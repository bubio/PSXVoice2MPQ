import 'dart:io';
import 'dart:typed_data';

Uint32List prepareEncryptionTable() {
  final table = Uint32List(0x500);
  int seed = 0x00100001;
  for (int i = 0; i < 256; i++) {
    int index = i;
    for (int j = 0; j < 5; j++) {
      seed = (seed * 125 + 3) % 0x2AAAAB;
      final temp1 = (seed & 0xFFFF) << 0x10;
      seed = (seed * 125 + 3) % 0x2AAAAB;
      final temp2 = (seed & 0xFFFF);
      table[index] = (temp1 | temp2).toUnsigned(32);
      index += 0x100;
    }
  }
  return table;
}

void decryptMpqBlock(Uint8List data, int key, Uint32List encryptionTable) {
  final Uint32List block = Uint32List.view(data.buffer, data.offsetInBytes, data.length ~/ 4);
  int length = block.length;
  int seed = 0xEEEEEEEE;
  int currentKey = key;

  for (int i = 0; i < length; i++) {
    seed = (seed + encryptionTable[0x400 + (currentKey & 0xFF)]).toUnsigned(32);
    int ch = block[i] ^ (currentKey + seed).toUnsigned(32);
    
    // Corrected update logic to match C precedence: ((~key << 0x15) + 0x11111111) | (key >> 0x0B)
    int part1 = (((~currentKey) & 0xFFFFFFFF) << 0x15).toUnsigned(32);
    part1 = (part1 + 0x11111111).toUnsigned(32);
    int part2 = (currentKey >> 0x0B).toUnsigned(32);
    currentKey = (part1 | part2).toUnsigned(32);

    seed = (ch + seed + (seed << 5) + 3).toUnsigned(32);
    block[i] = ch;
  }
}

void main() async {
  final encryptionTable = prepareEncryptionTable();
  final file = File('assets/test/ja.mpq');
  final bytes = await file.readAsBytes();

  final blockTableOffset = 0x2B24;
  final blockTableBytes = bytes.sublist(blockTableOffset, blockTableOffset + 3 * 16);
  decryptMpqBlock(blockTableBytes, 0xBBF107CE, encryptionTable);

  final view = ByteData.view(blockTableBytes.buffer);
  print('Decrypted Block Table (Reference MPQ):');
  for (int i = 0; i < 3; i++) {
    final offset = i * 16;
    final filePos = view.getUint32(offset, Endian.little);
    final cSize = view.getUint32(offset + 4, Endian.little);
    final fSize = view.getUint32(offset + 8, Endian.little);
    final flags = view.getUint32(offset + 12, Endian.little);
    print('Entry $i: Pos=$filePos, CSize=$cSize, FSize=$fSize, Flags=0x${flags.toRadixString(16).toUpperCase()}');
  }
}
