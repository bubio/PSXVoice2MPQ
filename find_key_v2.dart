import 'dart:typed_data';

Uint32List prepareTable() {
  final t = Uint32List(0x500);
  int s = 0x00100001;
  for (int i = 0; i < 256; i++) {
    for (int j = i, k = 0; k < 5; k++, j += 0x100) {
      s = (s * 125 + 3) % 0x2AAAAB;
      int t1 = (s & 0xFFFF) << 0x10;
      s = (s * 125 + 3) % 0x2AAAAB;
      int t2 = (s & 0xFFFF);
      t[j] = (t1 | t2).toUnsigned(32);
    }
  }
  return t;
}

void main() {
  final t = prepareTable();
  
  // Encrypted value at 0x2924: 0x1A51504D ('MPQ\x1A')
  const int cipher0 = 0x1A51504D;
  // Assume plain value is empty: 0xFFFFFFFF
  const int plain0 = 0xFFFFFFFF;
  
  // key1 + key2 = cipher ^ plain
  int key1plusKey2 = (cipher0 ^ plain0).toUnsigned(32); // 0xE5AEAFB2
  
  print('Searching for Key1 with overflow fix...');
  
  for (int i = 0; i < 256; i++) {
    // key2 = 0xEEEEEEEE + table[0x400 + (key1 & 0xFF)]
    int k1 = (key1plusKey2 - 0xEEEEEEEE - t[0x400 + i]).toUnsigned(32);
    if ((k1 & 0xFF) == i) {
      print('FOUND Potential Key1: 0x${k1.toRadixString(16).toUpperCase()}');
      
      // Let's verify with the next DWORD in ja.mpq at 0x2928: 0x00000020
      const int cipher1 = 0x00000020;
      const int plain1 = 0xFFFFFFFF; // Next DWORD also empty
      
      int dwKey1 = k1;
      int dwKey2 = (0xEEEEEEEE + t[0x400 + i]).toUnsigned(32);
      
      // Rotate k1, k2 as per StormLib
      dwKey1 = ((((~dwKey1) & 0xFFFFFFFF) << 0x15) + 0x11111111).toUnsigned(32) | (dwKey1 >>> 0x0B);
      dwKey1 = dwKey1.toUnsigned(32);
      dwKey2 = (plain0 + dwKey2 + (dwKey2 << 5).toUnsigned(32) + 3).toUnsigned(32);
      
      // Check next
      dwKey2 = (dwKey2 + t[0x400 + (dwKey1 & 0xFF)]).toUnsigned(32);
      int trialCipher1 = (plain1 ^ (dwKey1 + dwKey2)).toUnsigned(32);
      
      if (trialCipher1 == cipher1) {
        print('VERIFIED! Key1 is indeed 0x${k1.toRadixString(16).toUpperCase()}');
      } else {
        print('Verification failed for 0x${k1.toRadixString(16).toUpperCase()} (Expected 0x20, got 0x${trialCipher1.toRadixString(16).toUpperCase()})');
      }
    }
  }
}
