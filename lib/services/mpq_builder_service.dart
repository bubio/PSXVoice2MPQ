import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../core/constants/path_constants.dart';
import '../core/constants/stream_constants.dart';
import '../models/build_progress.dart';
import '../models/stream_mapping.dart';
import 'dstream_extractor.dart';
import 'process_runner.dart';
import 'stormlib_service.dart';
import 'super_resolution/super_resolution_service.dart';
import 'vag_to_wav_converter.dart';

class MpqBuilderService {
  final ProcessRunner _processRunner;
  final VagToWavConverter _vagToWavConverter;
  final DstreamExtractor _dstreamExtractor;
  final StormLibService _stormLibService;
  final SuperResolutionService _superResolution;

  bool _cancelled = false;

  MpqBuilderService({
    required this._processRunner,
    VagToWavConverter? vagToWavConverter,
    DstreamExtractor? dstreamExtractor,
    StormLibService? stormLibService,
    SuperResolutionService? superResolutionService,
  }) : _vagToWavConverter = vagToWavConverter ?? VagToWavConverter(),
       _dstreamExtractor = dstreamExtractor ?? DstreamExtractor(),
       _stormLibService = stormLibService ?? StormLibService(),
       _superResolution = superResolutionService ?? SuperResolutionService();

  void cancel() {
    _cancelled = true;
    _superResolution.cancel();
  }

  Stream<BuildProgress> build(
    String ps1AssetsPath,
    String outputPath, {
    bool superResolution = false,
  }) async* {
    _cancelled = false;

    var progress = BuildProgress(
      currentStep: '',
      stepKey: BuildStepKey.initializing,
    );

    try {
      // Check if output directory exists
      final outputDir = Directory(outputPath);
      if (!await outputDir.exists()) {
        yield progress.copyWith(
          errorKey: BuildErrorKey.outputDirectoryNotFound,
          isComplete: true,
        );
        return;
      }

      // Step 1: Check for StormLib FFI or smpq command
      final useStormLib = _stormLibService.initialize();
      String? smpqPath;

      if (useStormLib) {
        yield progress = progress.addLog(
          'Using bundled StormLib for MPQ creation',
        );
        yield progress = progress.addLog(
          'StormLib path: ${_stormLibService.libraryPath}',
        );
      } else {
        yield progress = progress.addLog('Checking for smpq command...');
        smpqPath = await _processRunner.findSmpq();
        if (smpqPath == null) {
          yield progress.copyWith(
            errorKey: BuildErrorKey.smpqNotFound,
            isComplete: true,
          );
          return;
        }
        yield progress = progress.addLog('smpq found at: $smpqPath');
      }

      // Check for lame or ffmpeg (optional MP3 encoding)
      final lamePath = await _processRunner.findLame();
      final ffmpegPath = lamePath == null
          ? await _processRunner.findFfmpeg()
          : null;
      final useMp3 = lamePath != null || ffmpegPath != null;
      final mp3EncoderPath = lamePath ?? ffmpegPath;
      final useFfmpeg = lamePath == null && ffmpegPath != null;
      if (lamePath != null) {
        yield progress = progress.addLog(
          'lame found at: $lamePath - MP3 encoding enabled',
        );
      } else if (ffmpegPath != null) {
        yield progress = progress.addLog(
          'ffmpeg found at: $ffmpegPath - MP3 encoding enabled (using ffmpeg)',
        );
      } else {
        yield progress = progress.addLog(
          'lame/ffmpeg not found - using WAV format',
        );
      }

      if (superResolution) {
        yield progress = progress.addLog(
          'Super-resolution: VoiceFixer (${_superResolution.modelDir})',
        );
      }

      // Step 2: Create temp directory
      final tempDir = Directory.systemTemp;
      final workDir = Directory(
        p.join(
          tempDir.path,
          '${PathConstants.workDirPrefix}${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await workDir.create(recursive: true);
      yield progress = progress.addLog('Work directory: ${workDir.path}');

      // Step 3: Find STREAM*.DIR files
      yield progress = progress.copyWith(
        stepKey: BuildStepKey.findingStreamFiles,
      );
      final assetsDir = Directory(ps1AssetsPath);
      final streamDirs = await assetsDir
          .list()
          .where((e) => e is File && _isStreamDir(e.path))
          .cast<File>()
          .toList();

      if (streamDirs.isEmpty) {
        yield progress.copyWith(
          errorKey: BuildErrorKey.noStreamFiles,
          isComplete: true,
        );
        return;
      }

      yield progress = progress.addLog(
        'Found ${streamDirs.length} stream file(s).',
      );

      // Step 4: Process each STREAM*.DIR
      // Steps: extract + vag conversion + [super-resolution] + [mp3] + mpq
      final stepsPerStream = 3 + (superResolution ? 1 : 0);
      int totalSteps = streamDirs.length * stepsPerStream;
      int currentStepNum = 0;

      for (final streamDir in streamDirs) {
        if (_cancelled) break;

        final streamName = p.basenameWithoutExtension(streamDir.path);
        final streamBin = streamDir.path.replaceFirst(
          RegExp(r'\.dir$', caseSensitive: false),
          '.BIN',
        );

        // Create stream work directory
        final streamWorkDir = Directory(
          p.join(workDir.path, '$streamName.DIR'),
        );
        await streamWorkDir.create(recursive: true);

        // Extract stream files using Dart implementation
        yield progress = progress.copyWith(
          stepKey: BuildStepKey.extractingStream,
          streamName: streamName,
          currentFile: streamDir.path,
          percentage: currentStepNum / totalSteps,
        );
        yield progress = progress.addLog('Extracting $streamName...');

        final dstreamResult = await _dstreamExtractor.extract(
          dirPath: streamDir.path,
          binPath: streamBin,
          outputDir: streamWorkDir.path,
        );

        if (!dstreamResult.isSuccess) {
          yield progress = progress.addLog(
            'Error: ${dstreamResult.errorMessage}. Skipping $streamName.',
          );
          currentStepNum += stepsPerStream; // Skip all steps for this stream
          continue;
        }

        yield progress = progress.addLog(
          'Extracted ${dstreamResult.extractedFiles.length} files from $streamName.',
        );
        currentStepNum++;
        if (_cancelled) break;

        // Load map file (needed to filter all processing steps)
        final streamNum = streamName.replaceAll(RegExp(r'[^0-9]'), '');
        final mapAssetPath = 'assets/maps/stream$streamNum.map';

        List<StreamMapping> mappings;
        try {
          final mapData = await rootBundle.loadString(mapAssetPath);
          mappings = _parseMappings(mapData);
          yield progress = progress.addLog(
            'Loaded ${mappings.length} mappings from stream$streamNum.map',
          );
        } catch (e) {
          yield progress = progress.addLog(
            'Warning: Could not load map file: $e',
          );
          mappings = [];
        }

        // Build set of map source files for filtering
        final mapSourceFiles = mappings
            .map((m) => m.sourceFile.toUpperCase())
            .toSet();

        // Convert VAG to WAV (parallel processing, filtered by map)
        yield progress = progress.copyWith(
          stepKey: BuildStepKey.convertingVagFiles,
          streamName: streamName,
          percentage: currentStepNum / totalSteps,
        );

        // Only convert VAG files whose WAV counterpart is in the map
        final mapVagFiles = mapSourceFiles
            .where((f) => f.endsWith('.WAV'))
            .map((f) => '${f.substring(0, f.length - 4)}.VAG')
            .toSet();

        final vagFiles = await streamWorkDir
            .list()
            .where(
              (e) =>
                  e is File &&
                  mapVagFiles.contains(p.basename(e.path).toUpperCase()),
            )
            .cast<File>()
            .toList();

        yield progress = progress.addLog(
          'Found ${vagFiles.length} VAG files to convert (filtered by map).',
        );

        // Parallel VAG to WAV conversion
        final numWorkers = (Platform.numberOfProcessors ~/ 2).clamp(1, 8);
        final vagConversionErrors = <String>[];

        yield progress = progress.copyWith(
          totalFiles: vagFiles.length,
          processedFiles: 0,
        );

        final batchSize = numWorkers;
        int processedCount = 0;

        for (
          int batchStart = 0;
          batchStart < vagFiles.length;
          batchStart += batchSize
        ) {
          if (_cancelled) break;
          final batchEnd = (batchStart + batchSize).clamp(0, vagFiles.length);
          final batch = vagFiles.sublist(batchStart, batchEnd);

          final futures = batch.map((vagFile) async {
            final wavPath =
                '${vagFile.path.substring(0, vagFile.path.length - 4)}.WAV';
            final result = await _vagToWavConverter.convert(
              vagFile.path,
              wavPath,
            );
            return (vagFile.path, result);
          }).toList();

          final results = await Future.wait(futures);

          for (final (vagPath, result) in results) {
            processedCount++;
            if (!result.isSuccess) {
              vagConversionErrors.add(
                '${p.basename(vagPath)}: ${result.errorMessage}',
              );
            }
          }

          yield progress = progress.copyWith(processedFiles: processedCount);
        }

        if (vagConversionErrors.isNotEmpty) {
          yield progress = progress.addLog(
            'Warning: ${vagConversionErrors.length} VAG files failed to convert',
          );
        }

        yield progress = progress.addLog(
          'Converted ${vagFiles.length} VAG files to WAV.',
        );
        currentStepNum++;
        if (_cancelled) break;

        // Super-resolution step (optional)
        if (superResolution && mappings.isNotEmpty) {
          yield progress = progress.copyWith(
            stepKey: BuildStepKey.enhancingAudio,
            streamName: streamName,
            percentage: currentStepNum / totalSteps,
          );

          yield* _runSuperResolution(
            streamWorkDir: streamWorkDir,
            mapSourceFiles: mapSourceFiles,
            progress: progress,
            onProgress: (p) => progress = p,
          );

          currentStepNum++;
          if (_cancelled) break;
        }

        // Convert WAV to MP3 if lame or ffmpeg is available (parallel processing)
        if (useMp3) {
          yield progress = progress.copyWith(
            stepKey: BuildStepKey.convertingToMp3,
            streamName: streamName,
            percentage: currentStepNum / totalSteps,
          );

          final wavFiles = await streamWorkDir
              .list()
              .where(
                (e) =>
                    e is File &&
                    mapSourceFiles.contains(p.basename(e.path).toUpperCase()),
              )
              .cast<File>()
              .toList();

          yield progress = progress.addLog(
            'Converting ${wavFiles.length} WAV files to MP3 (parallel processing)...',
          );

          yield progress = progress.copyWith(
            totalFiles: wavFiles.length,
            processedFiles: 0,
          );

          // MP3 quality: -V 4 for super-resolved (44.1kHz), -V 7 for original (11kHz)
          final mp3Quality = superResolution ? '4' : '7';

          final mp3BatchSize = (Platform.numberOfProcessors ~/ 2).clamp(1, 8);
          int mp3ProcessedCount = 0;
          final mp3Errors = <String>[];

          for (
            int batchStart = 0;
            batchStart < wavFiles.length;
            batchStart += mp3BatchSize
          ) {
            if (_cancelled) break;
            final batchEnd = (batchStart + mp3BatchSize).clamp(
              0,
              wavFiles.length,
            );
            final batch = wavFiles.sublist(batchStart, batchEnd);

            final futures = batch.map((wavFile) async {
              final mp3Path =
                  '${wavFile.path.substring(0, wavFile.path.length - 4)}.mp3';

              final ProcessResult result;
              if (useFfmpeg) {
                result = await _processRunner.run(mp3EncoderPath!, [
                  '-i',
                  wavFile.path,
                  '-codec:a',
                  'libmp3lame',
                  '-qscale:a',
                  mp3Quality,
                  '-y',
                  mp3Path,
                ]);
              } else {
                result = await _processRunner.run(mp3EncoderPath!, [
                  '--quiet',
                  '-V',
                  mp3Quality,
                  wavFile.path,
                  mp3Path,
                ]);
              }

              if (result.isSuccess) {
                await wavFile.delete();
              }
              return (wavFile.path, result.isSuccess);
            }).toList();

            final results = await Future.wait(futures);

            for (final (wavPath, isSuccess) in results) {
              mp3ProcessedCount++;
              if (!isSuccess) {
                mp3Errors.add(p.basename(wavPath));
              }
            }

            yield progress = progress.copyWith(
              processedFiles: mp3ProcessedCount,
            );
          }

          if (mp3Errors.isNotEmpty) {
            yield progress = progress.addLog(
              'Warning: ${mp3Errors.length} WAV files failed to convert to MP3',
            );
          }

          yield progress = progress.addLog(
            'Converted ${wavFiles.length} WAV files to MP3.',
          );
        }

        if (_cancelled) break;

        // Create mpq subdirectory and copy files according to mapping
        yield progress = progress.copyWith(
          stepKey: BuildStepKey.creatingMpq,
          streamName: streamName,
          percentage: currentStepNum / totalSteps,
        );

        final mpqDir = Directory(p.join(streamWorkDir.path, 'mpq'));
        await mpqDir.create(recursive: true);

        int mappedFiles = 0;
        for (final mapping in mappings) {
          var sourceFileName = mapping.sourceFile;
          var destPath = mapping.destinationPath;

          // If using MP3 and source is a WAV file, try MP3 version first
          if (useMp3 && sourceFileName.toUpperCase().endsWith('.WAV')) {
            final mp3SourceName =
                '${sourceFileName.substring(0, sourceFileName.length - 4)}.mp3';
            final mp3File = File(p.join(streamWorkDir.path, mp3SourceName));
            if (await mp3File.exists()) {
              sourceFileName = mp3SourceName;
              if (destPath.toUpperCase().endsWith('.WAV')) {
                destPath = '${destPath.substring(0, destPath.length - 4)}.mp3';
              }
            }
          }

          final sourceFile = File(p.join(streamWorkDir.path, sourceFileName));
          if (await sourceFile.exists()) {
            final fullDestPath = p.join(mpqDir.path, destPath);
            await Directory(p.dirname(fullDestPath)).create(recursive: true);
            await sourceFile.copy(fullDestPath);
            mappedFiles++;
          }
        }

        yield progress = progress.addLog(
          'Mapped $mappedFiles files according to mapping.',
        );

        // Create MPQ archive
        final langCode = StreamConstants.getLanguageCode(streamNum);
        final mpqPath = p.join(outputPath, '$langCode.mpq');

        yield progress = progress.addLog('Creating MPQ archive: $mpqPath');

        // Collect files to add
        final filesToAdd = await _listFilesRecursive(mpqDir);
        if (filesToAdd.isEmpty) {
          yield progress = progress.addLog(
            'Warning: No files to add for $streamName. Skipping MPQ creation.',
          );
          currentStepNum++;
          continue;
        }
        yield progress = progress.addLog(
          'Adding ${filesToAdd.length} files to MPQ...',
        );

        bool mpqCreated = false;

        // Try StormLib first
        if (useStormLib) {
          final fileEntries = filesToAdd.map((file) {
            final relativePath = p.relative(file.path, from: mpqDir.path);
            return MpqFileEntry(
              sourcePath: file.path,
              archivePath: relativePath,
            );
          }).toList();

          final stormResult = _stormLibService.createArchive(
            mpqPath,
            fileEntries,
          );

          if (stormResult.isSuccess) {
            mpqCreated = true;
            yield progress = progress.addLog(
              'MPQ created with StormLib: $mpqPath',
            );
          } else {
            yield progress = progress.addLog(
              'StormLib failed: ${stormResult.errorMessage}',
            );
            yield progress = progress.addLog('Falling back to smpq...');
          }
        }

        // Fall back to smpq if StormLib failed or wasn't available
        if (!mpqCreated && smpqPath != null) {
          final mpqFile = File(mpqPath);
          if (await mpqFile.exists()) {
            await mpqFile.delete();
          }

          var result = await _processRunner.run(smpqPath, [
            '-M',
            '1',
            '-C',
            'none',
            '-c',
            mpqPath,
          ]);
          if (!result.isSuccess) {
            yield progress = progress.addLog(
              'Error creating MPQ: ${result.stderr}',
            );
            currentStepNum++;
            continue;
          }

          for (final file in filesToAdd) {
            final relativePath = p.relative(file.path, from: mpqDir.path);
            result = await _processRunner.run(smpqPath, [
              '-a',
              '-C',
              'none',
              mpqPath,
              relativePath,
            ], workingDirectory: mpqDir.path);
          }

          mpqCreated = true;
          yield progress = progress.addLog('MPQ created with smpq: $mpqPath');
        }

        if (!mpqCreated) {
          yield progress = progress.addLog(
            'Error: Could not create MPQ - no MPQ creation method available',
          );
        }

        currentStepNum++;
      }

      // Cleanup
      yield progress = progress.copyWith(stepKey: BuildStepKey.cleaningUp);
      await workDir.delete(recursive: true);

      if (_cancelled) {
        yield progress.copyWith(isComplete: true).addLog('Build cancelled.');
      } else {
        yield progress
            .copyWith(
              stepKey: BuildStepKey.complete,
              percentage: 1.0,
              isComplete: true,
            )
            .addLog('Build complete!');
      }
    } catch (e, stackTrace) {
      yield progress.copyWith(
        error: 'Error: $e\n$stackTrace',
        isComplete: true,
      );
    }
  }

  /// Replaces the map-referenced WAV files in [streamWorkDir] with their
  /// super-resolved 44.1kHz versions.
  Stream<BuildProgress> _runSuperResolution({
    required Directory streamWorkDir,
    required Set<String> mapSourceFiles,
    required BuildProgress progress,
    required void Function(BuildProgress) onProgress,
  }) async* {
    final wavFiles = await streamWorkDir
        .list()
        .where(
          (e) =>
              e is File &&
              e.path.toUpperCase().endsWith('.WAV') &&
              mapSourceFiles.contains(p.basename(e.path).toUpperCase()),
        )
        .map((e) => e.path)
        .toList();
    wavFiles.sort();

    yield progress = progress.copyWith(
      totalFiles: wavFiles.length,
      processedFiles: 0,
    );
    onProgress(progress);

    var processed = 0;
    var fromCache = 0;
    await for (final event in _superResolution.enhance(wavFiles)) {
      final name = p.basename(wavFiles[event.index]);
      switch (event) {
        case SuperResolutionProgress():
          yield progress = progress.copyWith(currentFile: name);
        case SuperResolutionDone(:final cached):
          processed++;
          if (cached) fromCache++;
          yield progress = progress.copyWith(processedFiles: processed);
        case SuperResolutionSkipped(:final reason):
          processed++;
          yield progress = progress
              .copyWith(processedFiles: processed)
              .addLog('Super-resolution skipped $name: $reason');
      }
      onProgress(progress);
    }

    yield progress = progress.addLog(
      _cancelled
          ? 'Super-resolution cancelled.'
          : 'Super-resolution: $processed files ($fromCache from cache).',
    );
    onProgress(progress);
  }

  bool _isStreamDir(String path) {
    final name = p.basename(path).toUpperCase();
    return name.startsWith('STREAM') && name.endsWith('.DIR');
  }

  List<StreamMapping> _parseMappings(String mapData) {
    final mappings = <StreamMapping>[];
    for (final line in mapData.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        mappings.add(
          StreamMapping(sourceFile: parts[0], destinationPath: parts[1]),
        );
      }
    }
    return mappings;
  }

  Future<List<File>> _listFilesRecursive(Directory dir) async {
    final files = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  }
}
