import 'dart:async';
import 'dart:convert';
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
import 'vag_to_wav_converter.dart';
import 'wav_utils.dart' as wav_utils;

class MpqBuilderService {
  final ProcessRunner _processRunner;
  final VagToWavConverter _vagToWavConverter;
  final DstreamExtractor _dstreamExtractor;
  final StormLibService _stormLibService;

  Process? _audioSrProcess;
  bool _cancelled = false;

  MpqBuilderService({
    required ProcessRunner processRunner,
    VagToWavConverter? vagToWavConverter,
    DstreamExtractor? dstreamExtractor,
    StormLibService? stormLibService,
  }) : _processRunner = processRunner,
       _vagToWavConverter = vagToWavConverter ?? VagToWavConverter(),
       _dstreamExtractor = dstreamExtractor ?? DstreamExtractor(),
       _stormLibService = stormLibService ?? StormLibService();

  void cancel() {
    _cancelled = true;
    _audioSrProcess?.kill();
  }

  Stream<BuildProgress> build(
    String ps1AssetsPath,
    String outputPath, {
    String? audioSrPath,
    bool audioSrUseCpu = false,
    int audioSrChunkSeconds = 5,
  }) async* {
    _cancelled = false;
    _audioSrProcess = null;

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

      // Log AudioSR status
      if (audioSrPath != null) {
        yield progress = progress.addLog(
          'audiosr found at: $audioSrPath - audio enhancement enabled',
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
      // Steps: extract + vag conversion + [audiosr] + [mp3] + mpq
      final stepsPerStream = 3 + (audioSrPath != null ? 1 : 0);
      int totalSteps = streamDirs.length * stepsPerStream;
      int currentStepNum = 0;

      for (final streamDir in streamDirs) {
        if (_cancelled) break;

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
              gain: audioSrPath != null ? 2.0 : 1.0,
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

        // AudioSR enhancement step (optional)
        if (audioSrPath != null && mappings.isNotEmpty) {
          yield progress = progress.copyWith(
            stepKey: BuildStepKey.enhancingAudio,
            streamName: streamName,
            percentage: currentStepNum / totalSteps,
          );

          yield* _runAudioSr(
            audioSrPath: audioSrPath,
            streamName: streamName,
            streamWorkDir: streamWorkDir,
            mappings: mappings,
            progress: progress,
            onProgress: (p) => progress = p,
            useCpu: audioSrUseCpu,
            chunkSeconds: audioSrChunkSeconds,
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

          // MP3 quality: -V 4 for AudioSR-enhanced (48kHz), -V 7 for original (11kHz)
          final mp3Quality = audioSrPath != null ? '4' : '7';

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

      // Delete AudioSR cache after successful build
      if (!_cancelled && audioSrPath != null) {
        final audioCacheDir = Directory(
          p.join(PathConstants.getCacheDir(), 'audiosr'),
        );
        if (await audioCacheDir.exists()) {
          await audioCacheDir.delete(recursive: true);
          yield progress = progress.addLog('AudioSR cache cleared.');
        }
      }

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
    } finally {
      _audioSrProcess?.kill();
      _audioSrProcess = null;
    }
  }

  /// Run AudioSR enhancement on map-filtered WAV files with persistent caching.
  Stream<BuildProgress> _runAudioSr({
    required String audioSrPath,
    required String streamName,
    required Directory streamWorkDir,
    required List<StreamMapping> mappings,
    required BuildProgress progress,
    required void Function(BuildProgress) onProgress,
    required bool useCpu,
    required int chunkSeconds,
  }) async* {
    // Get the set of WAV source files referenced in the map
    final mapWavFiles = mappings
        .map((m) => m.sourceFile)
        .where((f) => f.toUpperCase().endsWith('.WAV'))
        .toSet();

    if (mapWavFiles.isEmpty) {
      yield progress = progress.addLog(
        'No WAV files in map, skipping AudioSR.',
      );
      onProgress(progress);
      return;
    }

    yield progress = progress.addLog(
      'AudioSR: ${mapWavFiles.length} WAV files in map for $streamName',
    );

    // Set up cache directory
    final cacheDir = Directory(PathConstants.getAudioSrCacheDir(streamName));
    await cacheDir.create(recursive: true);

    // Determine which files need processing (not yet cached)
    final filesToProcess = <String>[];
    final cachedFiles = <String>[];

    for (final fileName in mapWavFiles) {
      final cachedFile = File(p.join(cacheDir.path, fileName));
      if (await cachedFile.exists()) {
        cachedFiles.add(fileName);
      } else {
        filesToProcess.add(fileName);
      }
    }

    if (cachedFiles.isNotEmpty) {
      yield progress = progress.addLog(
        'AudioSR: ${cachedFiles.length} files already cached, skipping.',
      );
    }

    final totalFiles = mapWavFiles.length;
    yield progress = progress.copyWith(
      totalFiles: totalFiles,
      processedFiles: cachedFiles.length,
    );
    onProgress(progress);

    // Process uncached files with AudioSR (one file at a time)
    if (filesToProcess.isNotEmpty && !_cancelled) {
      yield progress = progress.addLog(
        'AudioSR: Processing ${filesToProcess.length} files...',
      );

      // Create output directory for AudioSR
      final audioSrOutDir = Directory(
        p.join(streamWorkDir.path, 'audiosr_out'),
      );
      await audioSrOutDir.create(recursive: true);

      try {
        int processedCount = 0;
        for (final fileName in filesToProcess) {
          if (_cancelled) break;

          yield progress = progress.addLog('AudioSR: Processing $fileName...');
          onProgress(progress);

          final inputFile = p.join(streamWorkDir.path, fileName);

          // Split input WAV into 5-second chunks
          final splitDir = Directory(
            p.join(streamWorkDir.path, 'audiosr_split'),
          );
          if (await splitDir.exists()) {
            await splitDir.delete(recursive: true);
          }
          await splitDir.create(recursive: true);

          const overlapSeconds = 0.1;
          final chunks = await wav_utils.splitWav(
            inputFile,
            splitDir.path,
            chunkSeconds,
            overlapSeconds: overlapSeconds,
          );
          yield progress = progress.addLog(
            'AudioSR: Split $fileName into ${chunks.length} chunk(s)',
          );
          onProgress(progress);

          // Process each chunk with AudioSR
          final outputChunks = <String>[];
          bool chunkFailed = false;

          for (int i = 0; i < chunks.length; i++) {
            if (_cancelled) break;

            yield progress = progress.addLog(
              'AudioSR: Processing chunk ${i + 1}/${chunks.length} of $fileName...',
            );
            onProgress(progress);

            // Clean output directory before each chunk
            if (await audioSrOutDir.exists()) {
              await audioSrOutDir.delete(recursive: true);
            }
            await audioSrOutDir.create(recursive: true);

            // Pre-resample chunk to 48kHz to avoid AudioSR internal
            // resampling issues (tensor dimension mismatch)
            final resampledPath = p.join(splitDir.path, 'chunk_resampled.WAV');
            await wav_utils.resampleWav(chunks[i], resampledPath, 48000);

            final audioSrArgs = [
              '-i',
              resampledPath,
              '-s',
              audioSrOutDir.path,
              '--model_name',
              'speech',
              if (useCpu) ...['-d', 'cpu'],
            ];
            _audioSrProcess = await _processRunner.startProcess(
              audioSrPath,
              audioSrArgs,
            );

            // Collect stderr into a buffer
            final stderrBuffer = StringBuffer();
            _audioSrProcess!.stderr
                .transform(utf8.decoder)
                .listen((data) => stderrBuffer.write(data));

            // Stream stdout lines to GUI log in real-time
            await for (final line
                in _audioSrProcess!.stdout
                    .transform(utf8.decoder)
                    .transform(const LineSplitter())) {
              if (line.trim().isNotEmpty) {
                yield progress = progress.addLog('AudioSR: $line');
                onProgress(progress);
              }
            }

            final exitCode = await _audioSrProcess!.exitCode;
            _audioSrProcess = null;

            if (_cancelled) break;

            // Find the output WAV file
            File? outputFile;
            await for (final entity in audioSrOutDir.list(recursive: true)) {
              if (entity is File &&
                  entity.path.toUpperCase().endsWith('.WAV')) {
                outputFile = entity;
                break;
              }
            }

            if (outputFile != null) {
              // Copy output to splitDir so it survives audioSrOutDir cleanup
              final savedPath = p.join(
                splitDir.path,
                'out_${i.toString().padLeft(3, '0')}.WAV',
              );
              await outputFile.copy(savedPath);
              outputChunks.add(savedPath);
            } else {
              chunkFailed = true;
              if (exitCode != 0) {
                yield progress = progress.addLog(
                  'AudioSR: Chunk ${i + 1} failed with code $exitCode',
                );
                final errMsg = stderrBuffer.toString().trim();
                if (errMsg.isNotEmpty) {
                  yield progress = progress.addLog('AudioSR error: $errMsg');
                }
              } else {
                yield progress = progress.addLog(
                  'AudioSR: Warning - no output for chunk ${i + 1} of $fileName',
                );
              }
              break;
            }
          }

          // Concatenate output chunks and cache
          if (!_cancelled && !chunkFailed && outputChunks.isNotEmpty) {
            final cachedPath = p.join(cacheDir.path, fileName);
            final crossfadeFrames = (overlapSeconds * 48000).round();
            await wav_utils.concatenateWavCrossfade(
              outputChunks,
              cachedPath,
              crossfadeFrames,
            );
            yield progress = progress.addLog(
              'AudioSR: Concatenated ${outputChunks.length} chunk(s) with crossfade and cached $fileName',
            );
          }

          // Clean up split directory
          if (await splitDir.exists()) {
            await splitDir.delete(recursive: true);
          }

          onProgress(progress);

          processedCount++;
          yield progress = progress.copyWith(
            processedFiles: cachedFiles.length + processedCount,
          );
          onProgress(progress);
        }

        if (_cancelled) {
          _audioSrProcess?.kill();
          yield progress = progress.addLog('AudioSR: Cancelled by user.');
        }
      } catch (e) {
        _audioSrProcess = null;
        yield progress = progress.addLog('AudioSR error: $e');
      }
    }

    // Copy all cached files to workDir (overwrite 11kHz WAV with 48kHz WAV)
    int copiedCount = 0;
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list()) {
        if (entity is File && entity.path.toUpperCase().endsWith('.WAV')) {
          final fileName = p.basename(entity.path);
          final destFile = File(p.join(streamWorkDir.path, fileName));
          await entity.copy(destFile.path);
          copiedCount++;
        }
      }
    }

    yield progress = progress.copyWith(processedFiles: totalFiles);
    onProgress(progress);

    yield progress = progress.addLog(
      'AudioSR: Copied $copiedCount enhanced files to work directory.',
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
