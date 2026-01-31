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

void main() {
  final t = prepareTable();
  final names = {
    'cow8': r'sfx\towners\cow8.wav',
    'rogue': r'sfx\rogue\rogue77.wav',
  };
  
  for (var entry in names.entries) {
    final hA = hashString(entry.value, 1, t);
    final hB = hashString(entry.value, 2, t);
    final hIdx = hashString(entry.value, 0, t) % 32;
    print('${entry.key}: HashA=0x${hA.toRadixString(16).toUpperCase()}, HashB=0x${hB.toRadixString(16).toUpperCase()}, Index=$hIdx');
  }
}
