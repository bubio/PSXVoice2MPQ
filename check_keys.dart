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

int hashString(String filePath, int type, Uint32List table) {
  int seed1 = 0x7FED7FED;
  int seed2 = 0xEEEEEEEE;
  for (int i = 0; i < filePath.length; i++) {
    int ch = filePath.codeUnitAt(i);
    // Already assumed uppercase here for this test
    seed1 = (table[(type << 8) + ch] ^ (seed1 + seed2)).toUnsigned(32);
    seed2 = (ch + seed1 + seed2 + (seed2 << 5) + 3).toUnsigned(32);
  }
  return seed1;
}

void main() {
  final table = prepareEncryptionTable();
  // Try with ALL CAPS
  final hashTableKey = hashString("(HASH TABLE)", 3, table);
  final blockTableKey = hashString("(BLOCK TABLE)", 3, table);
  print('Hash Table Key (Caps): 0x${hashTableKey.toRadixString(16).toUpperCase()}');
  print('Block Table Key (Caps): 0x${blockTableKey.toRadixString(16).toUpperCase()}');
}