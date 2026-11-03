"""VoiceFixer（mode 0）を、アプリで使う 3 つの ONNX グラフに変換する。

    vf_front.onnx  wav11k [1,1,n] -> unet_in [1,2,T,128], orig44k [1,1,4n]   ファイル全体で 1 回
    vf_back.onnx   unet_in [1,2,Tc,128] -> wav44k [1,1,Tc*441+1764]         区間ごと（畳み込みのみ）
    vf_post.onnx   orig44k, vf44k [1,1,4n] -> wav44k [1,1,4n]               4.8kHz 以下を元音声に差し替え

使い方（重みは ~/.cache/voicefixer に自動でダウンロードされる）:
    uv venv --python 3.10 && uv pip install voicefixer onnx scipy librosa
    python export.py <出力ディレクトリ>

仕様: docs/super-resolution.md
"""
import os
import sys

import numpy as np
import torch
import torch.nn.functional as F
import librosa
from scipy.signal import firwin
from voicefixer import VoiceFixer
from voicefixer.restorer.model_kqq_bn import UNetResComplex_100Mb
from voicefixer.tools.pytorch_util import from_log, to_log

DOWN = 64        # UNet のダウンサンプル比（2^6）
UP_RATIO = 4     # 11025Hz -> 44100Hz
OPSET = 17


def _unet_forward(self, sp):
    """本家の forward は np.ceil でパディング量を計算するため、トレースすると入力長が定数化される。
    同じ計算を整数演算で書き直し、可変長のまま ONNX に出せるようにする。"""
    t = sp.shape[2]
    x = F.pad(sp, pad=(0, 0, 0, (DOWN - t % DOWN) % DOWN))
    x = x[..., 0 : x.shape[-1] - 1]
    x1_pool, x1 = self.encoder_block1(x)
    x2_pool, x2 = self.encoder_block2(x1_pool)
    x3_pool, x3 = self.encoder_block3(x2_pool)
    x4_pool, x4 = self.encoder_block4(x3_pool)
    x5_pool, x5 = self.encoder_block5(x4_pool)
    x6_pool, x6 = self.encoder_block6(x5_pool)
    x = self.decoder_block1(self.conv_block7(x6_pool), x6)
    x = self.decoder_block2(x, x5)
    x = self.decoder_block3(x, x4)
    x = self.decoder_block4(x, x3)
    x = self.decoder_block5(x, x2)
    x = self.decoder_block6(x, x1)
    x = self.after_conv2(self.after_conv_block1(x))
    return {"mel": F.pad(x, pad=(0, 1))[:, :, 0:t, :]}


UNetResComplex_100Mb.forward = _unet_forward


def soxr_x4_kernel():
    """soxr_hq の 4 倍アップサンプルのインパルス応答。整数比なので、この FIR 1 本で soxr_hq と一致する（SNR 131dB）。

    戻り値: (kernel, offset)。offset は、ConvTranspose 相当の出力のうち soxr 出力の先頭に当たる位置。
    """
    n, c = 20000, 10000
    imp = np.zeros(n)
    imp[c] = 1.0
    y = librosa.resample(imp, orig_sr=11025, target_sr=44100, res_type="soxr_hq")
    nz = np.where(np.abs(y) > 1e-9)[0]
    lo, hi = nz.min() - UP_RATIO * c, nz.max() - UP_RATIO * c
    return y[UP_RATIO * c + lo : UP_RATIO * c + hi + 1], -lo


class Front(torch.nn.Module):
    """前段: 4 倍アップサンプル -> STFT -> mel -> 雑音除去（双方向 GRU）。GRU があるので分割しない。"""

    def __init__(self, vf):
        super().__init__()
        self.m = vf._model
        kernel, self.offset = soxr_x4_kernel()
        # ポリフェーズ分解: y[4q+p] = sum_i h[4i+p] x[q-i]。ORT では ConvTranspose で書くより大幅に速い。
        L = -(-len(kernel) // UP_RATIO)
        h = torch.zeros(L * UP_RATIO, dtype=torch.float32)
        h[: len(kernel)] = torch.tensor(kernel, dtype=torch.float32)
        self.register_buffer("w", h.reshape(L, UP_RATIO).t().flip(-1)[:, None, :])
        self.L = L

    def forward(self, wav11k):
        n44 = wav11k.shape[2] * UP_RATIO
        u = F.conv1d(wav11k, self.w, padding=self.L - 1).transpose(1, 2).reshape(1, 1, -1)
        u = u[:, :, self.offset : self.offset + n44]
        sp, _, _ = self.m.f_helper.wav_to_spectrogram_phase(u)
        mel = self.m.mel(sp.permute(0, 1, 3, 2)).permute(0, 1, 3, 2)
        clean = self.m.generator.denoiser(mel) * mel
        return torch.cat([to_log(mel), to_log(clean)], dim=1), u


class Back(torch.nn.Module):
    """後段: UNet -> ボコーダ。どちらも畳み込みのみなので、文脈付きで区間に分けても結果は変わらない。"""

    def __init__(self, vf):
        super().__init__()
        self.m = vf._model

    def forward(self, unet_in):
        mel = self.m.generator.unet(unet_in)["mel"] + unet_in[:, 1:2]
        return self.m.vocoder(from_log(mel))


class Post(torch.nn.Module):
    """後処理: y = vf + LP(orig - vf)。VoiceFixer は低域まで作り直して子音が欠けるので、低域は元音声を使う。"""

    def __init__(self):
        super().__init__()
        self.register_buffer("lp", torch.tensor(firwin(1023, 4800, fs=44100), dtype=torch.float32)[None, None, :])

    def forward(self, orig44k, vf44k):
        return vf44k + F.conv1d(orig44k - vf44k, self.lp, padding=511)


def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    vf = VoiceFixer()
    exports = [
        ("vf_front.onnx", Front(vf), (torch.randn(1, 1, 11025 * 5) * 0.1,),
         ["wav11k"], ["unet_in", "orig44k"], {"wav11k": {2: "n"}, "unet_in": {2: "t"}, "orig44k": {2: "m"}}),
        ("vf_back.onnx", Back(vf), (torch.randn(1, 2, 512, 128),),
         ["unet_in"], ["wav44k"], {"unet_in": {2: "t"}, "wav44k": {2: "m"}}),
        ("vf_post.onnx", Post(), (torch.randn(1, 1, 44100), torch.randn(1, 1, 44100)),
         ["orig44k", "vf44k"], ["wav44k"], {"orig44k": {2: "m"}, "vf44k": {2: "m"}, "wav44k": {2: "m"}}),
    ]
    with torch.no_grad():
        for name, model, args, inputs, outputs, axes in exports:
            path = os.path.join(out_dir, name)
            torch.onnx.export(model.eval(), args, path, input_names=inputs, output_names=outputs,
                              dynamic_axes=axes, opset_version=OPSET, dynamo=False)
            print("exported", path)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
