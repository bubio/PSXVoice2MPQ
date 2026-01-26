import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/services/dstream_extractor.dart';

void main() {
  group('DstreamExtractor', () {
    late DstreamExtractor extractor;
    final testDirPath = 'assets/test/STREAM5.DIR';
    final testBinPath = 'assets/test/STREAM5.BIN';
    final expectedVagPath = 'assets/test/J02F8.VAG';

    setUp(() {
      extractor = DstreamExtractor();
    });

    test('should read DIR file header correctly', () async {
      final dirFile = File(testDirPath);
      final dirData = await dirFile.readAsBytes();

      // Check magic 'LDIR'
      expect(String.fromCharCodes(dirData.sublist(0, 4)), equals('LDIR'));

      // Check entry count (little-endian)
      final entryCount =
          dirData[4] |
          (dirData[5] << 8) |
          (dirData[6] << 16) |
          (dirData[7] << 24);
      print('Entry count: $entryCount');
      expect(entryCount, equals(798));
    });

    test('should find J02F8.VAG entry in DIR', () async {
      final dirFile = File(testDirPath);
      final dirData = await dirFile.readAsBytes();

      final entryCount =
          dirData[4] |
          (dirData[5] << 8) |
          (dirData[6] << 16) |
          (dirData[7] << 24);

      bool found = false;
      for (int i = 0; i < entryCount; i++) {
        final entryOffset = 8 + (i * 20);
        final nameBytes = dirData.sublist(entryOffset + 8, entryOffset + 20);
        final nullIndex = nameBytes.indexOf(0);
        final name = String.fromCharCodes(
          nameBytes.sublist(0, nullIndex >= 0 ? nullIndex : nameBytes.length),
        );

        if (name == 'J02F8.VAG') {
          final offset =
              dirData[entryOffset] |
              (dirData[entryOffset + 1] << 8) |
              (dirData[entryOffset + 2] << 16) |
              (dirData[entryOffset + 3] << 24);
          final size =
              dirData[entryOffset + 4] |
              (dirData[entryOffset + 5] << 8) |
              (dirData[entryOffset + 6] << 16) |
              (dirData[entryOffset + 7] << 24);

          print('Found J02F8.VAG at entry $i');
          print('Offset: $offset (0x${offset.toRadixString(16)})');
          print('Size: $size (0x${size.toRadixString(16)})');

          expect(offset, equals(75597824)); // 0x04818800
          expect(size, equals(3600)); // 0x00000e10
          found = true;
          break;
        }
      }

      expect(found, isTrue, reason: 'J02F8.VAG entry should be found in DIR');
    });

    test('should debug VagBlock structure', () async {
      final binFile = File(testBinPath);
      final binData = await binFile.readAsBytes();

      // J02F8.VAG offset
      const offset = 75597824; // 0x04818800
      const expectedSize = 3600;

      print('BIN file size: ${binData.length}');
      print('J02F8.VAG offset: $offset');

      // Read VagBlock header
      final blockNum = binData[offset] | (binData[offset + 1] << 8);
      final unk02 = binData[offset + 2] | (binData[offset + 3] << 8);
      final blockSize = binData[offset + 4] | (binData[offset + 5] << 8);
      final unk06 = binData[offset + 6] | (binData[offset + 7] << 8);

      print('VagBlock:');
      print('  block_num: $blockNum');
      print('  unk02: $unk02');
      print('  block_size: $blockSize (0x${blockSize.toRadixString(16)})');
      print('  unk06: $unk06');

      final dataSize = blockSize - 128;
      print('  data_size: $dataSize');
      print('  expected_size: $expectedSize');

      expect(dataSize, equals(expectedSize));
    });

    test('should extract J02F8.VAG matching expected file', () async {
      final dirFile = File(testDirPath);
      final binFile = File(testBinPath);
      final expectedVagFile = File(expectedVagPath);

      final dirData = await dirFile.readAsBytes();
      final binData = await binFile.readAsBytes();
      final expectedVagData = await expectedVagFile.readAsBytes();

      print('DIR file size: ${dirData.length}');
      print('BIN file size: ${binData.length}');

      // Debug: manually search for J02F8.VAG in DIR
      // 'LDIR' as bytes [0x4C, 0x44, 0x49, 0x52], read little-endian = 0x5249444C
      const ldirMagic = 0x5249444C;
      final magic =
          dirData[0] |
          (dirData[1] << 8) |
          (dirData[2] << 16) |
          (dirData[3] << 24);
      print(
        'Magic: 0x${magic.toRadixString(16)} (expected: 0x${ldirMagic.toRadixString(16)})',
      );
      expect(magic, equals(ldirMagic));

      final entryCount =
          dirData[4] |
          (dirData[5] << 8) |
          (dirData[6] << 16) |
          (dirData[7] << 24);
      print('Entry count: $entryCount');

      // Search for J02F8.VAG
      bool found = false;
      for (int i = 0; i < entryCount; i++) {
        final off = 8 + (i * 20);
        final nameBytes = dirData.sublist(off + 8, off + 20);
        final nullIndex = nameBytes.indexOf(0);
        final name = String.fromCharCodes(
          nameBytes.sublist(0, nullIndex >= 0 ? nullIndex : nameBytes.length),
        );

        if (name.toUpperCase() == 'J02F8.VAG') {
          print('Found at entry $i: name="$name"');
          found = true;
          break;
        }
      }
      expect(
        found,
        isTrue,
        reason: 'J02F8.VAG should be found in manual search',
      );

      final extractedVag = extractor.extractVagByName(
        dirData: dirData,
        binData: binData,
        fileName: 'J02F8.VAG',
      );

      expect(
        extractedVag,
        isNotNull,
        reason: 'extractVagByName should not return null',
      );
      print('Extracted VAG size: ${extractedVag!.length} bytes');
      print('Expected VAG size: ${expectedVagData.length} bytes');

      expect(
        extractedVag.length,
        equals(expectedVagData.length),
        reason: 'Extracted VAG size should match expected',
      );
    });

    test('should produce VAG with correct header', () async {
      final dirFile = File(testDirPath);
      final binFile = File(testBinPath);
      final expectedVagFile = File(expectedVagPath);

      final dirData = await dirFile.readAsBytes();
      final binData = await binFile.readAsBytes();
      final expectedVagData = await expectedVagFile.readAsBytes();

      final extractedVag = extractor.extractVagByName(
        dirData: dirData,
        binData: binData,
        fileName: 'J02F8.VAG',
      );

      expect(extractedVag, isNotNull);

      // Compare VAG header (first 48 bytes)
      print('Comparing VAG headers (first 48 bytes)...');
      for (int i = 0; i < 48; i++) {
        if (extractedVag![i] != expectedVagData[i]) {
          print(
            'Header mismatch at offset $i: got 0x${extractedVag[i].toRadixString(16)}, expected 0x${expectedVagData[i].toRadixString(16)}',
          );
        }
      }

      // Check magic
      expect(String.fromCharCodes(extractedVag!.sublist(0, 4)), equals('VAGp'));

      // Check header matches
      expect(
        extractedVag.sublist(0, 48),
        equals(expectedVagData.sublist(0, 48)),
        reason: 'VAG headers should match',
      );
    });

    test('should produce VAG with matching ADPCM data', () async {
      final dirFile = File(testDirPath);
      final binFile = File(testBinPath);
      final expectedVagFile = File(expectedVagPath);

      final dirData = await dirFile.readAsBytes();
      final binData = await binFile.readAsBytes();
      final expectedVagData = await expectedVagFile.readAsBytes();

      final extractedVag = extractor.extractVagByName(
        dirData: dirData,
        binData: binData,
        fileName: 'J02F8.VAG',
      );

      expect(extractedVag, isNotNull);

      // Compare ADPCM data (after header)
      print('Comparing ADPCM data...');
      int mismatches = 0;
      for (
        int i = 48;
        i < extractedVag!.length && i < expectedVagData.length;
        i++
      ) {
        if (extractedVag[i] != expectedVagData[i]) {
          if (mismatches < 10) {
            print(
              'Data mismatch at offset $i: got 0x${extractedVag[i].toRadixString(16)}, expected 0x${expectedVagData[i].toRadixString(16)}',
            );
          }
          mismatches++;
        }
      }
      print('Total mismatches: $mismatches');

      expect(
        extractedVag,
        equals(expectedVagData),
        reason: 'Extracted VAG should exactly match expected file',
      );
    });

    test('should extract files to directory', () async {
      final outputDir = 'test_output_dstream';

      try {
        final result = await extractor.extract(
          dirPath: testDirPath,
          binPath: testBinPath,
          outputDir: outputDir,
          extensions: ['vag'],
        );

        expect(result.isSuccess, isTrue);
        print('Total entries: ${result.totalEntries}');
        print('Extracted files: ${result.extractedFiles.length}');

        // Check J02F8.VAG was extracted
        expect(result.extractedFiles.contains('J02F8.VAG'), isTrue);

        // Verify extracted file matches expected
        final extractedFile = File('$outputDir/J02F8.VAG');
        final expectedFile = File(expectedVagPath);

        expect(await extractedFile.exists(), isTrue);

        final extractedData = await extractedFile.readAsBytes();
        final expectedData = await expectedFile.readAsBytes();

        expect(extractedData, equals(expectedData));
      } finally {
        // Cleanup
        final dir = Directory(outputDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    });
  });
}
