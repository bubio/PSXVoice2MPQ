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

int hashString(String filePath, int type, Uint32List table) {
  int s1 = 0x7FED7FED, s2 = 0xEEEEEEEE;
  for (int i = 0; i < filePath.length; i++) {
    int ch = filePath.codeUnitAt(i);
    if (ch >= 97 && ch <= 122) ch -= 32;
    if (ch == 0x2F) ch = 0x5C;
    s1 = (table[(type << 8) + ch] ^ (s1 + s2)).toUnsigned(32);
    s2 = (ch + s1 + s2 + (s2 << 5).toUnsigned(32) + 3).toUnsigned(32);
  }
  return s1;
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
  final lBytes = bytes.sublist(10480, 10480 + 52);
  
  final baseKey = hashString("(listfile)", 3, t);
  print('Base Key: 0x${baseKey.toRadixString(16).toUpperCase()}');

  // Trial 1: key = baseKey + offset
  final trial1 = Uint8List.fromList(lBytes);
  decrypt(trial1, (baseKey + 10480).toUnsigned(32), t);
  print('Offset 10480 Result: ${String.fromCharCodes(trial1.map((b) => (b >= 32 && b < 127) ? b : 46))}');
  print('Hex: ${trial1.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');

  // Trial 2: key = (baseKey + offset) ^ size
  final trial2 = Uint8List.fromList(lBytes);
  decrypt(trial2, (baseKey + 10480).toUnsigned(32) ^ 52, t);
  print('Offset 10480 ^ 52 Result: ${String.fromCharCodes(trial2.map((b) => (b >= 32 && b < 127) ? b : 46))}');
}
