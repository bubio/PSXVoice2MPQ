import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/path_constants.dart';
import '../onnx/onnx_runtime.dart';
import '../onnx/voice_fixer.dart';
import 'wav_io.dart';

/// Result of enhancing one WAV file.
sealed class SuperResolutionEvent {
  /// Index of the file in the list passed to [SuperResolutionService.enhance].
  final int index;

  const SuperResolutionEvent(this.index);
}

/// Progress (0..1) within the file being processed.
final class SuperResolutionProgress extends SuperResolutionEvent {
  final double fraction;

  const SuperResolutionProgress(super.index, this.fraction);
}

/// The file was replaced with its enhanced version.
final class SuperResolutionDone extends SuperResolutionEvent {
  /// True if the result came from the cache without running the model.
  final bool cached;

  const SuperResolutionDone(super.index, {required this.cached});
}

/// The file was left unchanged.
final class SuperResolutionSkipped extends SuperResolutionEvent {
  final String reason;

  const SuperResolutionSkipped(super.index, this.reason);
}

/// Enhances 11025Hz voice WAV files to 44100Hz with VoiceFixer.
///
/// Results are cached by the SHA-256 of the input file, so files shared
/// between streams and files finished before a cancelled build are reused.
/// Inference runs in a background isolate.
class SuperResolutionService {
  /// Identifies the model files; changing the model must change this so old
  /// cache entries are not reused.
  static const modelVersion = 'voicefixer-v1';

  final String modelDir;
  final String cacheDir;

  /// [modelDir] and [cacheDir] default to the app data and cache directories.
  SuperResolutionService({String? modelDir, String? cacheDir})
    : modelDir =
          modelDir ??
          p.join(PathConstants.getAppDataDir(), 'models', modelVersion),
      cacheDir =
          cacheDir ?? p.join(PathConstants.getCacheDir(), 'sr', modelVersion);

  Isolate? _isolate;
  int? _terminateHandle;
  bool _cancelled = false;

  bool get isModelInstalled => VoiceFixer.modelFiles.every(
    (f) => File(p.join(modelDir, f)).existsSync(),
  );

  /// Replaces each file in [wavPaths] with its enhanced 44100Hz version.
  Stream<SuperResolutionEvent> enhance(List<String> wavPaths) async* {
    _cancelled = false;
    await Directory(cacheDir).create(recursive: true);

    // Serve what the cache already has; collect the rest for the model.
    final jobs = <_Job>[];
    for (var i = 0; i < wavPaths.length && !_cancelled; i++) {
      final path = wavPaths[i];
      final bytes = await File(path).readAsBytes();
      final audio = decodePcm16Mono(bytes);
      if (audio == null || audio.sampleRate != VoiceFixer.inputSampleRate) {
        yield SuperResolutionSkipped(i, 'not a 16-bit mono 11025Hz WAV');
        continue;
      }
      final cached = p.join(cacheDir, '${sha256.convert(bytes)}.wav');
      if (await File(cached).exists()) {
        await File(cached).copy(path);
        yield SuperResolutionDone(i, cached: true);
      } else {
        jobs.add(_Job(i, path, cached));
      }
    }
    if (jobs.isEmpty || _cancelled) return;

    final port = ReceivePort();
    final errors = ReceivePort();
    try {
      _isolate = await Isolate.spawn(
        _worker,
        (port.sendPort, modelDir, jobs),
        onError: errors.sendPort,
        onExit: port.sendPort,
        errorsAreFatal: true,
      );
      errors.listen((e) => port.sendPort.send(_WorkerFailed('$e')));

      await for (final message in port) {
        switch (message) {
          case int handle:
            _terminateHandle = handle;
            if (_cancelled) OnnxRuntime.requestTerminate(handle);
          case (int i, double fraction):
            yield SuperResolutionProgress(i, fraction);
          case (int i, String cached):
            await File(cached).copy(wavPaths[i]);
            yield SuperResolutionDone(i, cached: false);
          case _WorkerFailed(:final message):
            if (!_cancelled) {
              throw Exception('Super-resolution failed: $message');
            }
          case null:
            // onExit
            return;
        }
      }
    } finally {
      port.close();
      errors.close();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _terminateHandle = null;
    }
  }

  /// Stops [enhance]. Files already finished stay in the cache.
  void cancel() {
    _cancelled = true;
    final handle = _terminateHandle;
    if (handle != null) OnnxRuntime.requestTerminate(handle);
  }
}

final class _Job {
  final int index;
  final String input;
  final String cached;

  const _Job(this.index, this.input, this.cached);
}

final class _WorkerFailed {
  final String message;

  const _WorkerFailed(this.message);
}

/// Background isolate: runs the model on each job and writes the result to
/// its cache path (via a temporary file, so a cancelled run leaves no
/// partial entry).
void _worker((SendPort, String, List<_Job>) args) {
  final (port, modelDir, jobs) = args;
  final runtime = OnnxRuntime.open();
  try {
    port.send(runtime.terminateHandle);
    final fixer = VoiceFixer.load(runtime, modelDir);
    for (final job in jobs) {
      final audio = decodePcm16Mono(File(job.input).readAsBytesSync())!;
      final out = fixer.restore(
        audio.samples,
        onProgress: (v) => port.send((job.index, v)),
      );
      final partial = File('${job.cached}.part');
      partial.writeAsBytesSync(
        encodePcm16Mono(out, VoiceFixer.outputSampleRate),
        flush: true,
      );
      partial.renameSync(job.cached);
      port.send((job.index, job.cached));
    }
  } on OrtException catch (e) {
    port.send(_WorkerFailed(e.message));
  } finally {
    runtime.dispose();
  }
}
