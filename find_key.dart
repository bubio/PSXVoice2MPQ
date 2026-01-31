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

void main() async {
  final table = prepareEncryptionTable();
  
  // Hash Table starts at 0x2924 in ja.mpq
  // First 4 bytes are 0x4D, 0x50, 0x51, 0x1A (in hex: 1A51504D little endian)
  const int cipher0 = 0x1A51504D;
  const int plain0 = 0xFFFFFFFF; // Assume first entry is empty
  
  print('Searching for Key1...');
  
  for (int key1 = 0; key1 < 0xFFFFFFFF; key1++) {
    // This is too slow. Let's try key1 & 0xFF first
    if (key1 % 10000000 == 0) print('Progress: $key1');
    
    // Actually, we can derive key1 + key2
    // cipher = plain ^ (key1 + key2)
    // key1 + key2 = cipher ^ plain
    int key1plusKey2 = (cipher0 ^ plain0).toUnsigned(32); // 0xE5AEAFB2
    
    // key2 = 0xEEEEEEEE + table[0x400 + (key1 & 0xFF)]
    // key1 + 0xEEEEEEEE + table[0x400 + (key1 & 0xFF)] = 0xE5AEAFB2
    // key1 = 0xE5AEAFB2 - 0xEEEEEEEE - table[0x400 + (key1 & 0xFF)]
    
    for (int i = 0; i < 256; i++) {
      int k1 = (key1plusKey2 - 0xEEEEEEEE - table[0x400 + i]).toUnsigned(32);
      if ((k1 & 0xFF) == i) {
        print('Potential Key1 Found: 0x${k1.toRadixString(16).toUpperCase()}');
        
        // Verify with next DWORD (should also be 0xFFFFFFFF)
        // Reference 0x2928: 20 00 00 00
        // ... (Verification logic)
      }
    }
    break; 
  }
}
