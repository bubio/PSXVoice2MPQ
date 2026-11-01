import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'onnx_runtime.dart';

/// VoiceFixer super-resolution (11025Hz in, 44100Hz out) on ONNX Runtime.
///
/// Port of `restore()` in tools/voicefixer_onnx/pipeline.py; the outputs must
/// match. See docs/super-resolution.md for why each step exists.
final class VoiceFixer {
  /// Model files expected in the model directory.
  static const modelFiles = ['vf_front.onnx', 'vf_back.onnx', 'vf_post.onnx'];

  static const int inputSampleRate = 11025;
  static const int outputSampleRate = 44100;

  /// Fixed output delay in 44.1kHz samples.
  static const int _delay = 1244;

  /// Output samples per spectrogram frame.
  static const int _hop = 441;

  /// Largest frame count passed to the back model at once (~30.7s, ~3.3GB).
  static const int _window = 3072;

  /// Frames kept from each chunk when a file is longer than [_window].
  static const int _chunk = 1536;

  /// Context frames added on both sides of a chunk. With 768 the result
  /// matches whole-file inference to 66dB or better.
  static const int _context = 768;

  final OrtModel _front;
  final OrtModel _back;
  final OrtModel _post;

  VoiceFixer._(this._front, this._back, this._post);

  /// Loads the three models from [modelDir] into [runtime].
  factory VoiceFixer.load(OnnxRuntime runtime, String modelDir) {
    final models = [
      for (final file in modelFiles) runtime.loadModel(p.join(modelDir, file)),
    ];
    return VoiceFixer._(models[0], models[1], models[2]);
  }

  /// Restores [input] (mono, 11025Hz, -1.0..1.0) to mono 44100Hz audio of
  /// exactly `4 * input.length` samples.
  ///
  /// [onProgress] receives a value in 0..1 after each model run.
  Float32List restore(Float32List input, {void Function(double)? onProgress}) {
    final n44 = input.length * 4;

    final front = _front.run(
      {
        'wav11k': FloatTensor(input, [1, 1, input.length]),
      },
      ['unet_in', 'orig44k'],
    );
    final unetIn = front['unet_in']!;
    final original = front['orig44k']!;
    final frames = unetIn.shape[2];

    final chunkCount = frames <= _window ? 1 : (frames / _chunk).ceil();
    var done = 0;
    void step() => onProgress?.call(++done / (chunkCount + 2));
    step();

    final Float32List vocoded;
    if (frames <= _window) {
      vocoded = _runBack(unetIn);
      step();
    } else {
      final parts = <Float32List>[];
      for (var f0 = 0; f0 < frames; f0 += _chunk) {
        final f1 = math.min(frames, f0 + _chunk);
        final s0 = math.max(0, f0 - _context);
        final s1 = math.min(frames, f1 + _context);
        final y = _runBack(_sliceFrames(unetIn, s0, s1));
        // Drop the context and join as-is (no crossfade). Keep the tail of
        // the last chunk: the fixed delay below needs it.
        final start = (f0 - s0) * _hop;
        parts.add(
          Float32List.sublistView(
            y,
            start,
            f1 == frames ? y.length : (f1 - s0) * _hop,
          ),
        );
        step();
      }
      vocoded = _concat(parts);
    }

    final aligned = Float32List(n44);
    final available = math.max(0, math.min(n44, vocoded.length - _delay));
    aligned.setRange(0, available, vocoded, _delay);

    final post = _post.run(
      {
        'orig44k': original,
        'vf44k': FloatTensor(aligned, [1, 1, n44]),
      },
      ['wav44k'],
    );
    final out = post['wav44k']!.data;
    step();

    var peak = 0.0;
    for (final v in out) {
      final a = v.abs();
      if (a > peak) peak = a;
    }
    if (peak > 1.0) {
      final scale = 1.0 / peak;
      for (var i = 0; i < out.length; i++) {
        out[i] *= scale;
      }
    }
    return out;
  }

  Float32List _runBack(FloatTensor unetIn) =>
      _back.run({'unet_in': unetIn}, ['wav44k'])['wav44k']!.data;

  /// Frames [start, end) of a `[1, C, T, F]` tensor.
  static FloatTensor _sliceFrames(FloatTensor t, int start, int end) {
    final channels = t.shape[1];
    final frames = t.shape[2];
    final bins = t.shape[3];
    final length = end - start;
    final out = Float32List(channels * length * bins);
    for (var c = 0; c < channels; c++) {
      final src = (c * frames + start) * bins;
      out.setRange(c * length * bins, (c + 1) * length * bins, t.data, src);
    }
    return FloatTensor(out, [1, channels, length, bins]);
  }

  static Float32List _concat(List<Float32List> parts) {
    final out = Float32List(parts.fold(0, (n, x) => n + x.length));
    var offset = 0;
    for (final part in parts) {
      out.setAll(offset, part);
      offset += part.length;
    }
    return out;
  }
}
