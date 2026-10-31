import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/models/build_progress.dart';
import 'package:psxvoice2mpq/services/mpq_builder_service.dart';
import 'package:psxvoice2mpq/services/process_runner.dart';
import 'package:psxvoice2mpq/services/stormlib_service.dart';

import '../support/synthetic_stream.dart';

/// Reports no external tools, so the build takes the WAV-only path
/// regardless of what is installed on the machine running the test.
class _NoToolsProcessRunner extends ProcessRunner {
  @override
  Future<String?> findSmpq() async => null;
  @override
  Future<String?> findLame() async => null;
  @override
  Future<String?> findFfmpeg() async => null;
}

/// Captures the files handed to StormLib instead of loading the native
/// library, which `flutter test` cannot find outside an app bundle.
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
    // Read now: the build deletes its work directory once it finishes.
    archives[mpqPath] = {
      for (final f in files)
        p.posix.joinAll(p.split(f.archivePath)): File(
          f.sourcePath,
        ).readAsBytesSync(),
    };
    return MpqCreateResult.success(mpqPath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MpqBuilderService with synthetic stream data', () {
    late Directory inputDir;
    late Directory outputDir;
    late _RecordingStormLibService stormLib;
    late MpqBuilderService service;

    setUp(() async {
      inputDir = await Directory.systemTemp.createTemp('psx_in_');
      outputDir = await Directory.systemTemp.createTemp('psx_out_');
      await writeSyntheticStream(inputDir);
      stormLib = _RecordingStormLibService();
      service = MpqBuilderService(
        processRunner: _NoToolsProcessRunner(),
        stormLibService: stormLib,
      );
    });

    tearDown(() async {
      await inputDir.delete(recursive: true);
      await outputDir.delete(recursive: true);
    });

    test('builds en.mpq containing only the mapped WAV files', () async {
      final progress = await service.build(inputDir.path, outputDir.path).last;

      expect(progress.error, isNull);
      expect(progress.errorKey, isNull);
      expect(progress.stepKey, BuildStepKey.complete);

      final mpqPath = p.join(outputDir.path, 'en.mpq');
      expect(stormLib.archives.keys, [mpqPath]);

      final files = stormLib.archives[mpqPath]!;
      expect(
        files.keys,
        unorderedEquals(syntheticMappedEntries.values),
      );

      for (final wav in files.values) {
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
        // Header plus decoded PCM, so the tone actually came through
        expect(wav.length, greaterThan(44 + 1000));
      }
    });

    test('reports noStreamFiles for a folder without STREAM files', () async {
      final emptyDir = await Directory.systemTemp.createTemp('psx_empty_');
      addTearDown(() => emptyDir.delete(recursive: true));

      final progress = await service.build(emptyDir.path, outputDir.path).last;

      expect(progress.errorKey, BuildErrorKey.noStreamFiles);
      expect(stormLib.archives, isEmpty);
    });
  });
}
