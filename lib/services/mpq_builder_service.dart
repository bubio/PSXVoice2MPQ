import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/path_constants.dart';
import '../core/constants/stream_constants.dart';
import '../models/build_progress.dart';
import '../models/stream_mapping.dart';
import 'dstream_extractor.dart';
import 'process_runner.dart';
import 'stormlib_service.dart';
import 'vag_to_wav_converter.dart';

class MpqBuilderService {
  final ProcessRunner _processRunner;
  final VagToWavConverter _vagToWavConverter;
  final DstreamExtractor _dstreamExtractor;
  final StormLibService _stormLibService;

  MpqBuilderService({
    required ProcessRunner processRunner,
    VagToWavConverter? vagToWavConverter,
    DstreamExtractor? dstreamExtractor,
    StormLibService? stormLibService,
  })  : _processRunner = processRunner,
        _vagToWavConverter = vagToWavConverter ?? VagToWavConverter(),
        _dstreamExtractor = dstreamExtractor ?? DstreamExtractor(),
        _stormLibService = stormLibService ?? StormLibService();

  Stream<BuildProgress> build(
    String ps1AssetsPath,
    String outputPath,
  ) async* {
    var progress = BuildProgress(
      currentStep: '',
      stepKey: BuildStepKey.initializing,
    );

    try {
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
      final ffmpegPath = lamePath == null ? await _processRunner.findFfmpeg() : null;
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
        yield progress = progress.addLog('lame/ffmpeg not found - using WAV format');
      }

      // Step 2: Create temp directory
      final tempDir = await getTemporaryDirectory();
      final workDir = Directory(
        p.join(
          tempDir.path,
          '${PathConstants.workDirPrefix}${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await workDir.create(recursive: true);
      yield progress = progress.addLog('Work directory: ${workDir.path}');

      // Step 3: Find STREAM*.DIR files
      yield progress = progress.copyWith(stepKey: BuildStepKey.findingStreamFiles);
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
      int totalSteps = streamDirs.length * 3; // extract + vag conversion + mpq
      int currentStepNum = 0;

      for (final streamDir in streamDirs) {
        final streamName = p.basenameWithoutExtension(streamDir.path);
        final streamBin = streamDir.path.replaceAll('.DIR', '.BIN');

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
            'Extraction warning: ${dstreamResult.errorMessage}',
          );
        }

        yield progress = progress.addLog(
          'Extracted ${dstreamResult.extractedFiles.length} files from $streamName.',
        );
        currentStepNum++;

        // Convert VAG to WAV (parallel processing)
        yield progress = progress.copyWith(
          stepKey: BuildStepKey.convertingVagFiles,
          streamName: streamName,
          percentage: currentStepNum / totalSteps,
        );

        final vagFiles = await streamWorkDir
            .list()
            .where((e) => e is File && e.path.toUpperCase().endsWith('.VAG'))
            .cast<File>()
            .toList();

        yield progress = progress.addLog(
          'Found ${vagFiles.length} VAG files to convert (parallel processing).',
        );

        // Parallel VAG to WAV conversion
        // Use half of CPU cores to maintain UI responsiveness and reduce battery usage
        final numWorkers = (Platform.numberOfProcessors ~/ 2).clamp(1, 8);
        final vagConversionErrors = <String>[];

        yield progress = progress.copyWith(
          totalFiles: vagFiles.length,
          processedFiles: 0,
        );

        // Process in batches using Future.wait for parallelism
        final batchSize = numWorkers;
        int processedCount = 0;

        for (int batchStart = 0; batchStart < vagFiles.length; batchStart += batchSize) {
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

          yield progress = progress.copyWith(
            processedFiles: processedCount,
          );
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

        // Convert WAV to MP3 if lame or ffmpeg is available (parallel processing)
        if (useMp3) {
          yield progress = progress.copyWith(
            stepKey: BuildStepKey.convertingToMp3,
            streamName: streamName,
            percentage: currentStepNum / totalSteps,
          );

          final wavFiles = await streamWorkDir
              .list()
              .where((e) => e is File && e.path.toUpperCase().endsWith('.WAV'))
              .cast<File>()
              .toList();

          yield progress = progress.addLog(
            'Converting ${wavFiles.length} WAV files to MP3 (parallel processing)...',
          );

          yield progress = progress.copyWith(
            totalFiles: wavFiles.length,
            processedFiles: 0,
          );

          // Parallel MP3 conversion using Future.wait
          // Use half of CPU cores to maintain UI responsiveness and reduce battery usage
          final mp3BatchSize = (Platform.numberOfProcessors ~/ 2).clamp(1, 8);
          int mp3ProcessedCount = 0;
          final mp3Errors = <String>[];

          for (int batchStart = 0; batchStart < wavFiles.length; batchStart += mp3BatchSize) {
            final batchEnd = (batchStart + mp3BatchSize).clamp(0, wavFiles.length);
            final batch = wavFiles.sublist(batchStart, batchEnd);

            final futures = batch.map((wavFile) async {
              final mp3Path =
                  '${wavFile.path.substring(0, wavFile.path.length - 4)}.mp3';

              final ProcessResult result;
              if (useFfmpeg) {
                // Use ffmpeg for MP3 conversion (VBR quality 7 for 11kHz mono source)
                result = await _processRunner.run(mp3EncoderPath!, [
                  '-i',
                  wavFile.path,
                  '-codec:a',
                  'libmp3lame',
                  '-qscale:a',
                  '7',
                  '-y',
                  mp3Path,
                ]);
              } else {
                // Use lame for MP3 conversion (VBR quality 7 for 11kHz mono source)
                result = await _processRunner.run(mp3EncoderPath!, [
                  '--quiet',
                  '-V',
                  '7',
                  wavFile.path,
                  mp3Path,
                ]);
              }

              if (result.isSuccess) {
                // Delete the WAV file after successful conversion
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

        // Load map file and organize files
        yield progress = progress.copyWith(
          stepKey: BuildStepKey.creatingMpq,
          streamName: streamName,
          percentage: currentStepNum / totalSteps,
        );

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

        // Create mpq subdirectory and copy files according to mapping
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
            // Fall back to smpq
            yield progress = progress.addLog('Falling back to smpq...');
          }
        }

        // Fall back to smpq if StormLib failed or wasn't available
        if (!mpqCreated && smpqPath != null) {
          final mpqFile = File(mpqPath);
          if (await mpqFile.exists()) {
            await mpqFile.delete();
          }

          // Create new MPQ using smpq
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

          // Add files to MPQ using smpq
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

      yield progress
          .copyWith(
            stepKey: BuildStepKey.complete,
            percentage: 1.0,
            isComplete: true,
          )
          .addLog('Build complete!');
    } catch (e, stackTrace) {
      yield progress.copyWith(
        error: 'Error: $e\n$stackTrace',
        isComplete: true,
      );
    }
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
