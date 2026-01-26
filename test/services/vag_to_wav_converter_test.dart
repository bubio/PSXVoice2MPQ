import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/services/vag_to_wav_converter.dart';

void main() {
  group('VagToWavConverter', () {
    late VagToWavConverter converter;
    final testVagPath = 'assets/test/J02F8.VAG';
    final expectedWavPath = 'assets/test/J02F8.WAV';

    setUp(() {
      converter = VagToWavConverter();
    });

    test('should read VAG header correctly', () async {
      final vagFile = File(testVagPath);
      final vagData = await vagFile.readAsBytes();

      // Check magic
      expect(String.fromCharCodes(vagData.sublist(0, 4)), equals('VAGp'));

      // Check data size (big-endian at offset 12)
      final dataSize =
          (vagData[12] << 24) |
          (vagData[13] << 16) |
          (vagData[14] << 8) |
          vagData[15];
      print('Data size: $dataSize bytes');
      expect(dataSize, equals(0x0e10)); // 3600 bytes

      // Check sample rate (big-endian at offset 16)
      final sampleRate =
          (vagData[16] << 24) |
          (vagData[17] << 16) |
          (vagData[18] << 8) |
          vagData[19];
      print('Sample rate: $sampleRate Hz');
      expect(sampleRate, equals(11025));
    });

    test('should convert VAG to WAV with correct header', () async {
      final vagFile = File(testVagPath);
      final vagData = await vagFile.readAsBytes();

      final wavData = converter.convertBytes(vagData);
      expect(wavData, isNotNull);

      // Check RIFF header
      expect(String.fromCharCodes(wavData!.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wavData.sublist(8, 12)), equals('WAVE'));
      expect(String.fromCharCodes(wavData.sublist(12, 16)), equals('fmt '));
      expect(String.fromCharCodes(wavData.sublist(36, 40)), equals('data'));

      // Check sample rate in WAV (little-endian at offset 24)
      final wavSampleRate =
          wavData[24] |
          (wavData[25] << 8) |
          (wavData[26] << 16) |
          (wavData[27] << 24);
      print('WAV sample rate: $wavSampleRate Hz');
      expect(wavSampleRate, equals(11025));

      // Print WAV file size
      print('Generated WAV size: ${wavData.length} bytes');
    });

    test('should produce WAV with same size as expected', () async {
      final vagFile = File(testVagPath);
      final vagData = await vagFile.readAsBytes();
      final expectedWavFile = File(expectedWavPath);
      final expectedWavData = await expectedWavFile.readAsBytes();

      final wavData = converter.convertBytes(vagData);
      expect(wavData, isNotNull);

      print('Generated WAV size: ${wavData!.length} bytes');
      print('Expected WAV size: ${expectedWavData.length} bytes');

      // Check if sizes match
      expect(
        wavData.length,
        equals(expectedWavData.length),
        reason: 'WAV file sizes should match',
      );
    });

    test('should produce WAV with matching audio data', () async {
      final vagFile = File(testVagPath);
      final vagData = await vagFile.readAsBytes();
      final expectedWavFile = File(expectedWavPath);
      final expectedWavData = await expectedWavFile.readAsBytes();

      final wavData = converter.convertBytes(vagData);
      expect(wavData, isNotNull);

      // Compare headers (first 44 bytes)
      print('Comparing WAV headers...');
      for (int i = 0; i < 44; i++) {
        if (wavData![i] != expectedWavData[i]) {
          print(
            'Header mismatch at offset $i: got ${wavData[i]}, expected ${expectedWavData[i]}',
          );
        }
      }

      // Compare first few samples of audio data
      print('Comparing first 100 samples...');
      int mismatches = 0;
      for (int i = 44; i < 44 + 200 && i < wavData!.length; i += 2) {
        final gotSample = ByteData.sublistView(
          wavData,
          i,
          i + 2,
        ).getInt16(0, Endian.little);
        final expectedSample = ByteData.sublistView(
          expectedWavData,
          i,
          i + 2,
        ).getInt16(0, Endian.little);
        if (gotSample != expectedSample) {
          if (mismatches < 10) {
            print(
              'Sample mismatch at offset $i: got $gotSample, expected $expectedSample',
            );
          }
          mismatches++;
        }
      }
      print('Total mismatches in first 100 samples: $mismatches');

      // Full comparison
      expect(wavData, equals(expectedWavData));
    });

    test('should write WAV file correctly', () async {
      final outputPath = 'test_output.wav';

      try {
        final result = await converter.convert(testVagPath, outputPath);
        expect(result.isSuccess, isTrue);

        final outputFile = File(outputPath);
        expect(await outputFile.exists(), isTrue);

        final outputData = await outputFile.readAsBytes();
        final expectedWavFile = File(expectedWavPath);
        final expectedWavData = await expectedWavFile.readAsBytes();

        expect(outputData.length, equals(expectedWavData.length));
      } finally {
        // Cleanup
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      }
    });
  });
}
