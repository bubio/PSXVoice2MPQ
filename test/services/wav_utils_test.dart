import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/services/wav_utils.dart' as wav_utils;

void main() {
  group('wav_utils', () {
    final testInputPath = 'assets/test/J019B.WAV';
    final testOutputDir = 'assets/test';

    test('splitWav should split WAV into 5-second chunks', () async {
      final inputFile = File(testInputPath);
      expect(
        await inputFile.exists(),
        isTrue,
        reason: 'Test input file must exist',
      );

      // Read original file info
      final originalBytes = await inputFile.readAsBytes();
      final originalData = ByteData.sublistView(originalBytes);
      final sampleRate = originalData.getUint32(24, Endian.little);
      final numChannels = originalData.getUint16(22, Endian.little);
      final bitsPerSample = originalData.getUint16(34, Endian.little);
      final blockAlign = numChannels * (bitsPerSample ~/ 8);

      print('Input: ${originalBytes.length} bytes');
      print('Format: ${sampleRate}Hz, ${numChannels}ch, ${bitsPerSample}bit');

      // Find original data size
      int origDataSize = 0;
      int offset = 12;
      while (offset < originalBytes.length - 8) {
        final chunkId = String.fromCharCodes(
          originalBytes.sublist(offset, offset + 4),
        );
        final chunkSize = originalData.getUint32(offset + 4, Endian.little);
        if (chunkId == 'data') {
          origDataSize = chunkSize;
          break;
        }
        offset += 8 + chunkSize;
      }
      print('PCM data size: $origDataSize bytes');

      final totalSamples = origDataSize ~/ blockAlign;
      final totalSeconds = totalSamples / sampleRate;
      final expectedChunks = (totalSeconds / 5).ceil();
      print('Duration: ${totalSeconds.toStringAsFixed(2)}s');
      print('Expected chunks: $expectedChunks');

      // Split
      final chunks = await wav_utils.splitWav(testInputPath, testOutputDir, 5);

      print('Actual chunks: ${chunks.length}');
      for (final chunk in chunks) {
        print('  $chunk (${File(chunk).lengthSync()} bytes)');
      }

      // Verify chunk count
      expect(chunks.length, equals(expectedChunks));

      // Verify each chunk is a valid WAV file
      for (int i = 0; i < chunks.length; i++) {
        final chunkFile = File(chunks[i]);
        expect(await chunkFile.exists(), isTrue, reason: 'Chunk $i must exist');

        final chunkBytes = await chunkFile.readAsBytes();
        final chunkData = ByteData.sublistView(chunkBytes);

        // Check RIFF header
        expect(String.fromCharCodes(chunkBytes.sublist(0, 4)), equals('RIFF'));
        expect(String.fromCharCodes(chunkBytes.sublist(8, 12)), equals('WAVE'));

        // Check format matches original
        expect(chunkData.getUint16(22, Endian.little), equals(numChannels));
        expect(chunkData.getUint32(24, Endian.little), equals(sampleRate));
        expect(chunkData.getUint16(34, Endian.little), equals(bitsPerSample));

        // Check chunk PCM data size
        int chunkPcmSize = 0;
        int off = 12;
        while (off < chunkBytes.length - 8) {
          final id = String.fromCharCodes(chunkBytes.sublist(off, off + 4));
          final size = chunkData.getUint32(off + 4, Endian.little);
          if (id == 'data') {
            chunkPcmSize = size;
            break;
          }
          off += 8 + size;
        }

        if (i < chunks.length - 1) {
          // Non-last chunks should be exactly 5 seconds
          final expectedSize = sampleRate * 5 * blockAlign;
          expect(
            chunkPcmSize,
            equals(expectedSize),
            reason: 'Chunk $i should be exactly 5 seconds',
          );
        } else {
          // Last chunk should be <= 5 seconds
          final maxLastChunkSize = sampleRate * 5 * blockAlign;
          expect(
            chunkPcmSize,
            greaterThan(0),
            reason: 'Last chunk must have data',
          );
          expect(
            chunkPcmSize,
            lessThanOrEqualTo(maxLastChunkSize),
            reason: 'Last chunk must be <= 5 seconds',
          );
        }
      }
    });

    test(
      'concatenateWav should reassemble split chunks to match original',
      () async {
        // First split
        final chunks = await wav_utils.splitWav(
          testInputPath,
          testOutputDir,
          5,
        );
        expect(chunks.isNotEmpty, isTrue);

        // Concatenate
        final outputPath = '$testOutputDir/J019B_concatenated.WAV';
        await wav_utils.concatenateWav(chunks, outputPath);

        final outputFile = File(outputPath);
        expect(
          await outputFile.exists(),
          isTrue,
          reason: 'Concatenated file must exist',
        );

        // Read original and concatenated files
        final originalBytes = await File(testInputPath).readAsBytes();
        final outputBytes = await outputFile.readAsBytes();

        final originalData = ByteData.sublistView(originalBytes);
        final outputData = ByteData.sublistView(outputBytes);

        // Format should match
        expect(
          outputData.getUint16(22, Endian.little),
          equals(originalData.getUint16(22, Endian.little)),
          reason: 'numChannels must match',
        );
        expect(
          outputData.getUint32(24, Endian.little),
          equals(originalData.getUint32(24, Endian.little)),
          reason: 'sampleRate must match',
        );
        expect(
          outputData.getUint16(34, Endian.little),
          equals(originalData.getUint16(34, Endian.little)),
          reason: 'bitsPerSample must match',
        );

        // Find PCM data in both files
        int findDataOffset(Uint8List bytes, ByteData bd) {
          int off = 12;
          while (off < bytes.length - 8) {
            final id = String.fromCharCodes(bytes.sublist(off, off + 4));
            if (id == 'data') return off + 8;
            off += 8 + bd.getUint32(off + 4, Endian.little);
          }
          return -1;
        }

        int findDataSize(Uint8List bytes, ByteData bd) {
          int off = 12;
          while (off < bytes.length - 8) {
            final id = String.fromCharCodes(bytes.sublist(off, off + 4));
            if (id == 'data') return bd.getUint32(off + 4, Endian.little);
            off += 8 + bd.getUint32(off + 4, Endian.little);
          }
          return -1;
        }

        final origDataOffset = findDataOffset(originalBytes, originalData);
        final origDataSize = findDataSize(originalBytes, originalData);
        final outDataOffset = findDataOffset(outputBytes, outputData);
        final outDataSize = findDataSize(outputBytes, outputData);

        print('Original PCM: offset=$origDataOffset, size=$origDataSize');
        print('Output PCM:   offset=$outDataOffset, size=$outDataSize');

        // PCM data size must match
        expect(
          outDataSize,
          equals(origDataSize),
          reason: 'PCM data size must match after split+concatenate',
        );

        // PCM data content must be byte-identical
        final origPcm = originalBytes.sublist(
          origDataOffset,
          origDataOffset + origDataSize,
        );
        final outPcm = outputBytes.sublist(
          outDataOffset,
          outDataOffset + outDataSize,
        );
        expect(
          outPcm,
          equals(origPcm),
          reason: 'PCM data must be byte-identical after split+concatenate',
        );

        print('Split+concatenate roundtrip: PASSED (byte-identical)');
      },
    );

    test(
      'splitWav with overlap + concatenateWavCrossfade roundtrip',
      () async {
        final inputFile = File(testInputPath);
        expect(await inputFile.exists(), isTrue);

        // Read original WAV info
        final originalBytes = await inputFile.readAsBytes();
        final originalData = ByteData.sublistView(originalBytes);
        final sampleRate = originalData.getUint32(24, Endian.little);
        final numChannels = originalData.getUint16(22, Endian.little);
        final bitsPerSample = originalData.getUint16(34, Endian.little);
        final blockAlign = numChannels * (bitsPerSample ~/ 8);

        // Find original PCM data size
        int origDataSize = 0;
        int offset = 12;
        while (offset < originalBytes.length - 8) {
          final chunkId = String.fromCharCodes(
            originalBytes.sublist(offset, offset + 4),
          );
          final chunkSize =
              originalData.getUint32(offset + 4, Endian.little);
          if (chunkId == 'data') {
            origDataSize = chunkSize;
            break;
          }
          offset += 8 + chunkSize;
        }
        final origFrames = origDataSize ~/ blockAlign;

        // Split without overlap (baseline)
        final chunksNoOverlap = await wav_utils.splitWav(
          testInputPath,
          testOutputDir,
          5,
        );

        // Split with 0.1s overlap
        const overlapSeconds = 0.1;
        final chunksOverlap = await wav_utils.splitWav(
          testInputPath,
          testOutputDir,
          5,
          overlapSeconds: overlapSeconds,
        );

        print('Chunks without overlap: ${chunksNoOverlap.length}');
        print('Chunks with overlap: ${chunksOverlap.length}');

        // With overlap, we should get at least as many chunks
        expect(
          chunksOverlap.length,
          greaterThanOrEqualTo(chunksNoOverlap.length),
          reason: 'Overlap should produce at least as many chunks',
        );

        // Crossfade concatenation
        final crossfadeFrames = (overlapSeconds * sampleRate).round();
        final outputPath = '$testOutputDir/J019B_crossfade.WAV';
        await wav_utils.concatenateWavCrossfade(
          chunksOverlap,
          outputPath,
          crossfadeFrames,
        );

        final outputFile = File(outputPath);
        expect(await outputFile.exists(), isTrue);

        // Read output WAV info
        final outBytes = await outputFile.readAsBytes();
        final outData = ByteData.sublistView(outBytes);

        // Verify format preserved
        expect(
          outData.getUint16(22, Endian.little),
          equals(numChannels),
        );
        expect(
          outData.getUint32(24, Endian.little),
          equals(sampleRate),
        );
        expect(
          outData.getUint16(34, Endian.little),
          equals(bitsPerSample),
        );

        // Find output data size
        int outDataSize = 0;
        int outOffset = 12;
        while (outOffset < outBytes.length - 8) {
          final chunkId = String.fromCharCodes(
            outBytes.sublist(outOffset, outOffset + 4),
          );
          final chunkSize =
              outData.getUint32(outOffset + 4, Endian.little);
          if (chunkId == 'data') {
            outDataSize = chunkSize;
            break;
          }
          outOffset += 8 + chunkSize;
        }
        final outFrames = outDataSize ~/ blockAlign;

        print('Original frames: $origFrames');
        print('Crossfade output frames: $outFrames');

        // Output frame count should match original exactly
        expect(
          outFrames,
          equals(origFrames),
          reason:
              'Crossfade concatenation should produce the same number of frames as original',
        );

        // Clean up overlap chunks
        for (final chunk in chunksOverlap) {
          final f = File(chunk);
          if (await f.exists()) await f.delete();
        }
      },
    );

    test('resampleWav should resample 11025Hz WAV to 48000Hz', () async {
      final inputFile = File(testInputPath);
      expect(
        await inputFile.exists(),
        isTrue,
        reason: 'Test input file must exist',
      );

      // Read original file info
      final originalBytes = await inputFile.readAsBytes();
      final originalData = ByteData.sublistView(originalBytes);
      final origSampleRate = originalData.getUint32(24, Endian.little);
      final numChannels = originalData.getUint16(22, Endian.little);
      final bitsPerSample = originalData.getUint16(34, Endian.little);
      final blockAlign = numChannels * (bitsPerSample ~/ 8);

      // Find original data size
      int origDataSize = 0;
      int offset = 12;
      while (offset < originalBytes.length - 8) {
        final chunkId = String.fromCharCodes(
          originalBytes.sublist(offset, offset + 4),
        );
        final chunkSize =
            originalData.getUint32(offset + 4, Endian.little);
        if (chunkId == 'data') {
          origDataSize = chunkSize;
          break;
        }
        offset += 8 + chunkSize;
      }

      final origFrames = origDataSize ~/ blockAlign;
      print('Original: ${origSampleRate}Hz, $origFrames frames');

      // Resample to 48000Hz
      const targetRate = 48000;
      final outputPath = '$testOutputDir/J019B_resampled.WAV';
      await wav_utils.resampleWav(testInputPath, outputPath, targetRate);

      final outputFile = File(outputPath);
      expect(
        await outputFile.exists(),
        isTrue,
        reason: 'Resampled file must exist',
      );

      // Read output file info
      final outBytes = await outputFile.readAsBytes();
      final outData = ByteData.sublistView(outBytes);

      // Check RIFF header
      expect(String.fromCharCodes(outBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(outBytes.sublist(8, 12)), equals('WAVE'));

      // Check sample rate is 48000Hz
      final outSampleRate = outData.getUint32(24, Endian.little);
      expect(outSampleRate, equals(targetRate));

      // Check other format fields preserved
      expect(
        outData.getUint16(22, Endian.little),
        equals(numChannels),
        reason: 'numChannels must be preserved',
      );
      expect(
        outData.getUint16(34, Endian.little),
        equals(bitsPerSample),
        reason: 'bitsPerSample must be preserved',
      );

      // Find output data size and verify frame count ratio
      int outDataSize = 0;
      int outOffset = 12;
      while (outOffset < outBytes.length - 8) {
        final chunkId = String.fromCharCodes(
          outBytes.sublist(outOffset, outOffset + 4),
        );
        final chunkSize =
            outData.getUint32(outOffset + 4, Endian.little);
        if (chunkId == 'data') {
          outDataSize = chunkSize;
          break;
        }
        outOffset += 8 + chunkSize;
      }

      final outFrames = outDataSize ~/ blockAlign;
      final expectedRatio = targetRate / origSampleRate;
      final actualRatio = outFrames / origFrames;
      print('Output: ${outSampleRate}Hz, $outFrames frames');
      print(
        'Expected ratio: ${expectedRatio.toStringAsFixed(4)}, '
        'actual ratio: ${actualRatio.toStringAsFixed(4)}',
      );

      // Allow ±1 frame tolerance due to rounding
      expect(
        (outFrames - (origFrames * expectedRatio).round()).abs(),
        lessThanOrEqualTo(1),
        reason: 'Frame count should match expected ratio (48000/11025)',
      );
    });

    tearDownAll(() async {
      // Clean up generated chunk files, concatenated file, and resampled file
      final dir = Directory(testOutputDir);
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.startsWith('J019B_') && name.endsWith('.WAV')) {
            await entity.delete();
            print('Cleaned up: $name');
          }
        }
      }
    });
  });
}
