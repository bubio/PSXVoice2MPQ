import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/build_progress.dart';
import '../models/stream_mapping.dart';
import 'binary_extractor.dart';
import 'process_runner.dart';

class MpqBuilderService {
  final BinaryExtractor _binaryExtractor = BinaryExtractor();
  final ProcessRunner _processRunner = ProcessRunner();

  Stream<BuildProgress> build(String ps1AssetsPath, String outputPath, AppLocalizations l10n) async* {
    var progress = BuildProgress(currentStep: l10n.initializing);

    try {
      // Step 1: Check for smpq
      yield progress = progress.addLog('Checking for smpq command...');
      final smpqPath = await _processRunner.findSmpq();
      if (smpqPath == null) {
        yield progress.copyWith(
          error: l10n.errorSmpqNotFound,
          isComplete: true,
        );
        return;
      }
      yield progress = progress.addLog('smpq found at: $smpqPath');

      // Step 2: Extract binaries
      yield progress = progress.copyWith(currentStep: l10n.extractingBinaries);
      yield progress = progress.addLog('Extracting bundled binaries...');
      await _binaryExtractor.extractBinaries();
      final dstreamPath = await _binaryExtractor.getDstreamPath();
      final vag2wavPath = await _binaryExtractor.getVag2WavPath();
      yield progress = progress.addLog('Binaries extracted.');

      // Step 3: Create temp directory
      final tempDir = await getTemporaryDirectory();
      final workDir = Directory(p.join(tempDir.path, 'psx_mpq_work_${DateTime.now().millisecondsSinceEpoch}'));
      await workDir.create(recursive: true);
      yield progress = progress.addLog('Work directory: ${workDir.path}');

      // Step 4: Find STREAM*.DIR files
      yield progress = progress.copyWith(currentStep: l10n.findingStreamFiles);
      final assetsDir = Directory(ps1AssetsPath);
      final streamDirs = await assetsDir
          .list()
          .where((e) => e is File && _isStreamDir(e.path))
          .cast<File>()
          .toList();

      if (streamDirs.isEmpty) {
        yield progress.copyWith(
          error: l10n.errorNoStreamFiles,
          isComplete: true,
        );
        return;
      }

      yield progress = progress.addLog('Found ${streamDirs.length} stream file(s).');

      // Step 5: Process each STREAM*.DIR
      int totalSteps = streamDirs.length * 3; // dstream + vag2wav + mpq
      int currentStepNum = 0;

      for (final streamDir in streamDirs) {
        final streamName = p.basenameWithoutExtension(streamDir.path);
        final streamBin = streamDir.path.replaceAll('.DIR', '.BIN');

        // Create stream work directory
        final streamWorkDir = Directory(p.join(workDir.path, '$streamName.DIR'));
        await streamWorkDir.create(recursive: true);

        // Run dstream
        yield progress = progress.copyWith(
          currentStep: l10n.extractingStream(streamName),
          currentFile: streamDir.path,
          percentage: currentStepNum / totalSteps,
        );
        yield progress = progress.addLog('Running dstream on $streamName...');

        final dstreamResult = await _processRunner.run(
          dstreamPath,
          [streamDir.path, streamBin],
          workingDirectory: streamWorkDir.path,
        );

        if (!dstreamResult.isSuccess) {
          yield progress = progress.addLog('dstream warning: ${dstreamResult.stderr}');
        }

        // Count extracted files
        final extractedFiles = await streamWorkDir
            .list()
            .where((e) => e is File)
            .toList();
        yield progress = progress.addLog('Extracted ${extractedFiles.length} files from $streamName.');
        currentStepNum++;

        // Convert VAG to WAV
        yield progress = progress.copyWith(
          currentStep: l10n.convertingVagFiles(streamName),
          percentage: currentStepNum / totalSteps,
        );

        final vagFiles = await streamWorkDir
            .list()
            .where((e) => e is File && e.path.toUpperCase().endsWith('.VAG'))
            .cast<File>()
            .toList();

        yield progress = progress.addLog('Found ${vagFiles.length} VAG files to convert.');

        for (int i = 0; i < vagFiles.length; i++) {
          final vagFile = vagFiles[i];
          final wavPath = '${vagFile.path.substring(0, vagFile.path.length - 4)}.WAV';

          yield progress = progress.copyWith(
            currentFile: p.basename(vagFile.path),
            totalFiles: vagFiles.length,
            processedFiles: i,
          );

          final result = await _processRunner.run(vag2wavPath, [vagFile.path, wavPath]);
          if (!result.isSuccess) {
            yield progress = progress.addLog('Warning: Failed to convert ${p.basename(vagFile.path)}');
          }
        }

        yield progress = progress.addLog('Converted ${vagFiles.length} VAG files.');
        currentStepNum++;

        // Load map file and organize files
        yield progress = progress.copyWith(
          currentStep: l10n.creatingMpq(streamName),
          percentage: currentStepNum / totalSteps,
        );

        final streamNum = streamName.replaceAll(RegExp(r'[^0-9]'), '');
        final mapAssetPath = 'assets/maps/stream$streamNum.map';

        List<StreamMapping> mappings;
        try {
          final mapData = await rootBundle.loadString(mapAssetPath);
          mappings = _parseMappings(mapData);
          yield progress = progress.addLog('Loaded ${mappings.length} mappings from stream$streamNum.map');
        } catch (e) {
          yield progress = progress.addLog('Warning: Could not load map file: $e');
          mappings = [];
        }

        // Create mpq subdirectory and copy files according to mapping
        final mpqDir = Directory(p.join(streamWorkDir.path, 'mpq'));
        await mpqDir.create(recursive: true);

        int mappedFiles = 0;
        for (final mapping in mappings) {
          final sourceFile = File(p.join(streamWorkDir.path, mapping.sourceFile));
          if (await sourceFile.exists()) {
            final destPath = p.join(mpqDir.path, mapping.destinationPath);
            await Directory(p.dirname(destPath)).create(recursive: true);
            await sourceFile.copy(destPath);
            mappedFiles++;
          }
        }

        yield progress = progress.addLog('Mapped $mappedFiles files according to mapping.');

        // Create MPQ archive
        final mpqPath = p.join(outputPath, 'stream$streamNum.mpq');
        final mpqFile = File(mpqPath);
        if (await mpqFile.exists()) {
          await mpqFile.delete();
        }

        yield progress = progress.addLog('Creating MPQ archive: $mpqPath');

        // Create new MPQ
        var result = await _processRunner.run(smpqPath, ['-M', '1', '-C', 'none', '-c', mpqPath]);
        if (!result.isSuccess) {
          yield progress = progress.addLog('Error creating MPQ: ${result.stderr}');
          currentStepNum++;
          continue;
        }

        // Add files to MPQ
        final filesToAdd = await _listFilesRecursive(mpqDir);
        yield progress = progress.addLog('Adding ${filesToAdd.length} files to MPQ...');

        for (final file in filesToAdd) {
          final relativePath = p.relative(file.path, from: mpqDir.path);
          result = await _processRunner.run(
            smpqPath,
            ['-a', '-C', 'none', mpqPath, relativePath],
            workingDirectory: mpqDir.path,
          );
        }

        yield progress = progress.addLog('MPQ created: $mpqPath');
        currentStepNum++;
      }

      // Cleanup
      yield progress = progress.copyWith(currentStep: l10n.cleaningUp);
      await workDir.delete(recursive: true);

      yield progress.copyWith(
        currentStep: l10n.complete,
        percentage: 1.0,
        isComplete: true,
      ).addLog('Build complete!');
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
        mappings.add(StreamMapping(
          sourceFile: parts[0],
          destinationPath: parts[1],
        ));
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
