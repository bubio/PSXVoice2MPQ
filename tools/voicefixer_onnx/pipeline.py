"""アプリ（Dart）の超解像処理のリファレンス実装。Dart 版の出力はこれと一致させる。

使い方: python pipeline.py <モデルのディレクトリ> <入力 11025Hz WAV> <出力 44100Hz WAV>
"""
import os
import sys

import numpy as np
import onnxruntime as ort
import soundfile as sf

DELAY = 1244  # 出力の固定遅延（44.1kHz のサンプル数）。本家の中央トリムは入力長によって 2〜7ms 揺れるので使わない
HOP = 441
WIN = 3072    # 後段に一度に渡す最大フレーム数（約 30.7 秒、ピーク約 3.3GB。3584 にすると 5.3GB に跳ねる）
CHUNK = 1536  # 分割するときに残す区間（64 の倍数）。CHUNK + 2*CTX <= WIN
CTX = 768     # 分割するときに前後に付ける文脈（64 の倍数）。全体処理との一致は 66dB 以上（1024 で 106dB）


def load(model_dir):
    so = ort.SessionOptions()
    return [ort.InferenceSession(os.path.join(model_dir, f), so, providers=["CPUExecutionProvider"])
            for f in ("vf_front.onnx", "vf_back.onnx", "vf_post.onnx")]


def restore(sessions, x11):
    front, back, post = sessions
    n44 = len(x11) * 4
    unet_in, orig44 = front.run(None, {"wav11k": x11[None, None, :]})
    t = unet_in.shape[2]
    if t <= WIN:
        y = back.run(None, {"unet_in": unet_in})[0][0, 0]
    else:
        outs = []
        for f0 in range(0, t, CHUNK):
            f1 = min(t, f0 + CHUNK)
            s0, s1 = max(0, f0 - CTX), min(t, f1 + CTX)
            yc = back.run(None, {"unet_in": np.ascontiguousarray(unet_in[:, :, s0:s1])})[0][0, 0]
            # 文脈の部分を捨ててそのままつなぐ（クロスフェードしない）。最後の区間は末尾まで残す
            outs.append(yc[(f0 - s0) * HOP:] if f1 == t else yc[(f0 - s0) * HOP:(f1 - s0) * HOP])
        y = np.concatenate(outs)
    y = np.pad(y, (0, max(0, DELAY + n44 - len(y))))[DELAY:DELAY + n44]
    y = post.run(None, {"orig44k": orig44, "vf44k": y[None, None, :].astype(np.float32)})[0][0, 0]
    peak = np.abs(y).max()
    return y / peak if peak > 1.0 else y


if __name__ == "__main__":
    model_dir, src, dst = sys.argv[1:4]
    x, sr = sf.read(src, dtype="float32")
    assert sr == 11025 and x.ndim == 1, "11025Hz モノラルの WAV を指定してください"
    sf.write(dst, restore(load(model_dir), x), 44100)
