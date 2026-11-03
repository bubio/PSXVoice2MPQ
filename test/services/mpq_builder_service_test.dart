import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/models/build_progress.dart';
import 'package:psxvoice2mpq/services/mpq_builder_service.dart';
import 'package:psxvoice2mpq/services/process_runner.dart';
import 'package:psxvoice2mpq/services/stormlib_service.dart';
import 'package:psxvoice2mpq/services/super_resolution/colab_exchange.dart';
import 'package:psxvoice2mpq/services/super_resolution/super_resolution_service.dart';
import 'package:psxvoice2mpq/services/super_resolution/wav_io.dart';

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
        p.posix.joinAll(p.split(f.archivePath)): File(f.sourcePath)
            .readAsBytesSync(),
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
    late Directory cacheDir;
    late MpqBuilderService service;

    setUp(() async {
      inputDir = await Directory.systemTemp.createTemp('psx_in_');
      outputDir = await Directory.systemTemp.createTemp('psx_out_');
      cacheDir = await Directory.systemTemp.createTemp('psx_sr_');
      await writeSyntheticStream(inputDir);
      stormLib = _RecordingStormLibService();
      service = MpqBuilderService(
        processRunner: _NoToolsProcessRunner(),
        stormLibService: stormLib,
        superResolutionService: SuperResolutionService(
          modelDir: p.join(cacheDir.path, 'no-model'),
          cacheDir: cacheDir.path,
        ),
      );
    });

    tearDown(() async {
      await inputDir.delete(recursive: true);
      await outputDir.delete(recursive: true);
      await cacheDir.delete(recursive: true);
    });

    test('builds en.mpq containing only the mapped WAV files', () async {
      final progress = await service.build(inputDir.path, outputDir.path).last;

      expect(progress.error, isNull);
      expect(progress.errorKey, isNull);
      expect(progress.stepKey, BuildStepKey.complete);

      final mpqPath = p.join(outputDir.path, 'en.mpq');
      expect(stormLib.archives.keys, [mpqPath]);

      final files = stormLib.archives[mpqPath]!;
      expect(files.keys, unorderedEquals(syntheticMappedEntries.values));

      for (final wav in files.values) {
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
        // Header plus decoded PCM, so the tone actually came through
        expect(wav.length, greaterThan(44 + 1000));
      }
    });

    test('Colab round trip: export, import the result, build', () async {
      final exported = await service
          .exportForColab(inputDir.path, outputDir.path, appVersion: '9.9.9')
          .last;
      expect(exported.error, isNull);
      expect(stormLib.archives, isEmpty);

      // Stand in for the notebook: answer every exported voice with 44.1kHz.
      final input = ZipDecoder().decodeBytes(
        File(p.join(outputDir.path, ColabExchange.inputZipName))
            .readAsBytesSync(),
      );
      final manifest = jsonDecode(
        utf8.decode(input.findFile('manifest.json')!.content),
      );
      // The synthetic voices share one payload, so one file goes out.
      expect(manifest['files'], hasLength(1));
      final result = Archive()
        ..add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
      for (final f in input.files.where((f) => f.name.startsWith('wav/'))) {
        final samples = decodePcm16Mono(f.content)!.samples;
        result.add(
          ArchiveFile.bytes(
            f.name,
            encodePcm16Mono(Float32List(samples.length * 4), 44100),
          ),
        );
      }
      final resultPath = p.join(outputDir.path, 'sr_output.zip');
      File(resultPath).writeAsBytesSync(ZipEncoder().encodeBytes(result));
      final imported = await ColabExchange(cacheDir: cacheDir.path)
          .importResult(resultPath);
      expect(imported, 1);

      final progress = await service
          .build(
            inputDir.path,
            outputDir.path,
            superResolution: SuperResolutionMode.colab,
          )
          .last;
      expect(progress.error, isNull);
      final files = stormLib.archives[p.join(outputDir.path, 'en.mpq')]!;
      expect(files, hasLength(syntheticMappedEntries.length));
      for (final wav in files.values) {
        expect(decodePcm16Mono(wav)!.sampleRate, 44100);
      }
    });

    test('Colab mode keeps voices without a result at 11kHz', () async {
      final progress = await service
          .build(
            inputDir.path,
            outputDir.path,
            superResolution: SuperResolutionMode.colab,
          )
          .last;

      expect(progress.error, isNull);
      expect(progress.logs.join('\n'), contains('no Colab result'));
      final files = stormLib.archives[p.join(outputDir.path, 'en.mpq')]!;
      for (final wav in files.values) {
        expect(decodePcm16Mono(wav)!.sampleRate, 11025);
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
