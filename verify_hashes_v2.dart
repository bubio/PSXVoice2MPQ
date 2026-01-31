import 'dart:io';
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

void decrypt(Uint8List d, int k, Uint32List t) {
  final b = Uint32List.view(d.buffer, d.offsetInBytes, d.length ~/ 4);
  int k1 = k, k2 = 0xEEEEEEEE;
  for (int i = 0; i < b.length; i++) {
    k2 = (k2 + t[0x400 + (k1 & 0xFF)]).toUnsigned(32);
    int cipher = b[i];
    int plain = (cipher ^ (k1 + k2)).toUnsigned(32);
    k1 = ((((~k1) & 0xFFFFFFFF) << 0x15) + 0x11111111).toUnsigned(32) | (k1 >>> 0x0B);
    k1 = k1.toUnsigned(32);
    k2 = (plain + k2 + (k2 << 5).toUnsigned(32) + 3).toUnsigned(32);
    b[i] = plain;
  }
}

void main() async {
  final t = prepareTable();
  final bytes = await File('assets/test/ja.mpq').readAsBytes();
  
  // Decrypt Hash Table at 0x2924 with CALCULATED key 0xC3AF3770
  final hBytes = bytes.sublist(10532, 11044);
  decrypt(hBytes, 0xC3AF3770, t); 
  
  final view = ByteData.view(hBytes.buffer);
  print('--- Decrypted Hash Table (Key: 0xC3AF3770) ---');
  for (int i = 0; i < 32; i++) {
    final off = i * 16;
    final bIdx = view.getUint32(off + 12, Endian.little);
    if (bIdx != 0xFFFFFFFF) {
      final h1 = view.getUint32(off, Endian.little);
      final h2 = view.getUint32(off + 4, Endian.little);
      print('Index $i: HashA=0x${h1.toRadixString(16).toUpperCase()}, HashB=0x${h2.toRadixString(16).toUpperCase()}, BlockIdx=$bIdx');
    }
  }
}
