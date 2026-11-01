import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/models/build_progress.dart';
import 'package:psxvoice2mpq/services/mpq_builder_service.dart';
import 'package:psxvoice2mpq/services/process_runner.dart';
import 'package:psxvoice2mpq/services/stormlib_service.dart';
import 'package:psxvoice2mpq/services/super_resolution/super_resolution_service.dart';
import 'package:psxvoice2mpq/services/super_resolution/wav_io.dart';

import '../support/local_test_data.dart';

/// Directory with vf_front/back/post.onnx (built by tools/voicefixer_onnx).
final _modelDir = Platform.environment['VOICEFIXER_MODEL_DIR'];

class _NoToolsProcessRunner extends ProcessRunner {
  @override
  Future<String?> findSmpq() async => null;
  @override
  Future<String?> findLame() async => null;
  @override
  Future<String?> findFfmpeg() async => null;
}

class _RecordingStormLibService extends StormLibService {
  final archives = <String, Map<String, Uint8List>>{};

  @override
  bool initialize() => true;

  @override
  String? get libraryPath => 'fake';

  @override
  MpqCreateResult createArchive(
    String mpqPath,
    List<MpqFileEntry> files, {
    int compression = 0,
  }) {
    archives[mpqPath] = {
      for (final f in files)
        f.archivePath: File(f.sourcePath).readAsBytesSync(),
    };
    return MpqCreateResult.success(mpqPath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Runs VoiceFixer on every mapped voice of STREAM5 (about 40 minutes on an
  // Apple M4), so it only runs when the model and the local PSX data exist.
  test(
    'super-resolution replaces every mapped voice with 44.1kHz audio',
    () async {
      final inputDir = await Directory.systemTemp.createTemp('psx_sr_in_');
      final outputDir = await Directory.systemTemp.createTemp('psx_sr_out_');
      final cacheDir = await Directory.systemTemp.createTemp('psx_sr_cache_');
      addTearDown(() async {
        for (final d in [inputDir, outputDir, cacheDir]) {
          await d.delete(recursive: true);
        }
      });
      for (final name in ['STREAM5.DIR', 'STREAM5.BIN']) {
        await File(p.join('assets/test', name))
            .copy(p.join(inputDir.path, name));
      }

      final stormLib = _RecordingStormLibService();
      final service = MpqBuilderService(
        processRunner: _NoToolsProcessRunner(),
        stormLibService: stormLib,
        superResolutionService: SuperResolutionService(
          modelDir: _modelDir,
          cacheDir: cacheDir.path,
        ),
      );

      final progress = await service
          .build(inputDir.path, outputDir.path, superResolution: true)
          .last;

      expect(progress.error, isNull);
      expect(progress.stepKey, BuildStepKey.complete);
      expect(
        progress.logs.where((l) => l.contains('skipped')),
        isEmpty,
        reason: 'every voice should be enhanced',
      );

      final files = stormLib.archives.values.single;
      final wavs = files.entries.where(
        (e) => e.key.toUpperCase().endsWith('.WAV'),
      );
      expect(wavs, isNotEmpty);
      for (final MapEntry(key: name, value: bytes) in wavs) {
        expect(decodePcm16Mono(bytes)?.sampleRate, 44100, reason: name);
      }
    },
    skip: _modelDir == null
        ? 'Set VOICEFIXER_MODEL_DIR to run super-resolution'
        : skipWithoutLocalTestData,
    timeout: const Timeout(Duration(hours: 2)),
  );
}
