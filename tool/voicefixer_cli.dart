// Runs VoiceFixer on one WAV file, for checking the Dart port against
// tools/voicefixer_onnx/pipeline.py.
//
// fvm dart run tool/voicefixer_cli.dart <libonnxruntime> <model dir> <in.wav> <out.f32>
//
// <in.wav> must be 16-bit mono 11025Hz. <out.f32> is raw little-endian
// float32 at 44100Hz.
import 'dart:io';
import 'dart:typed_data';

import 'package:psxvoice2mpq/services/onnx/onnx_runtime.dart';
import 'package:psxvoice2mpq/services/onnx/voice_fixer.dart';

Float32List readPcm16Mono(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  if (data.getUint16(22, Endian.little) != 1 ||
      data.getUint32(24, Endian.little) != VoiceFixer.inputSampleRate ||
      data.getUint16(34, Endian.little) != 16) {
    throw FormatException('Expected 16-bit mono 11025Hz WAV: $path');
  }
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes, offset, offset + 4);
    final size = data.getUint32(offset + 4, Endian.little);
    if (id == 'data') {
      final count = size ~/ 2;
      final out = Float32List(count);
      for (var i = 0; i < count; i++) {
        out[i] = data.getInt16(offset + 8 + i * 2, Endian.little) / 32768.0;
      }
      return out;
    }
    offset += 8 + size + (size & 1);
  }
  throw FormatException('No data chunk: $path');
}

void main(List<String> args) {
  if (args.length != 4) {
    stderr.writeln(
      'usage: voicefixer_cli <libonnxruntime> <model dir> <in.wav> <out.f32>',
    );
    exit(64);
  }
  final [libPath, modelDir, inPath, outPath] = args;
  final input = readPcm16Mono(inPath);

  final sw = Stopwatch()..start();
  final runtime = OnnxRuntime.open(libPath);
  final fixer = VoiceFixer.load(runtime, modelDir);
  final loadMs = sw.elapsedMilliseconds;

  sw.reset();
  final out = fixer.restore(
    input,
    onProgress: (v) => stdout.write('\r${(v * 100).round()}%'),
  );
  stdout.writeln();
  final runMs = sw.elapsedMilliseconds;
  runtime.dispose();

  File(outPath).writeAsBytesSync(out.buffer.asUint8List());
  final seconds = input.length / VoiceFixer.inputSampleRate;
  stdout.writeln(
    '${seconds.toStringAsFixed(1)}s audio, load ${loadMs}ms, '
    'run ${runMs}ms (RTF ${(runMs / 1000 / seconds).toStringAsFixed(2)}), '
    'out ${out.length} samples',
  );
}
