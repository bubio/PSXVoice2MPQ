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

int hashString(String filePath, int type, Uint32List table) {
  int seed1 = 0x7FED7FED;
  int seed2 = 0xEEEEEEEE;
  for (int i = 0; i < filePath.length; i++) {
    int ch = filePath.codeUnitAt(i);
    if (ch >= 97 && ch <= 122) ch -= 32; // toupper
    if (ch == 0x2F) ch = 0x5C; // / -> \
    seed1 = (table[(type << 8) + ch] ^ (seed1 + seed2)).toUnsigned(32);
    seed2 = (ch + seed1 + seed2 + (seed2 << 5) + 3).toUnsigned(32);
  }
  return seed1;
}

void decryptMpqBlock(Uint8List data, int key, Uint32List table) {
  final Uint32List block = Uint32List.view(data.buffer, data.offsetInBytes, data.length ~/ 4);
  int dwKey1 = key;
  int dwKey2 = 0xEEEEEEEE;
  for (int i = 0; i < block.length; i++) {
    dwKey2 = (dwKey2 + table[0x400 + (dwKey1 & 0xFF)]).toUnsigned(32);
    int cipher = block[i];
    int plain = (cipher ^ (dwKey1 + dwKey2)).toUnsigned(32);
    dwKey1 = ((((~dwKey1) & 0xFFFFFFFF) << 0x15) + 0x11111111).toUnsigned(32) | (dwKey1 >> 0x0B);
    dwKey1 = dwKey1.toUnsigned(32);
    dwKey2 = (plain + dwKey2 + (dwKey2 << 5) + 3).toUnsigned(32);
    block[i] = plain;
  }
}

void main() async {
  final table = prepareEncryptionTable();
  final baseKey = hashString("(listfile)", 3, table);
  
  final file = File('assets/test/ja.mpq');
  final bytes = await file.readAsBytes();
  final data = bytes.sublist(10480, 10480 + 52);

  // Trial: key = baseKey + offset
  final key = (baseKey + 10480).toUnsigned(32);
  decryptMpqBlock(data, key, table);
  
  print('DECRYPTED (listfile):');
  print(data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" "));
  print(String.fromCharCodes(data).replaceAll("\r", "\\r").replaceAll("\n", "\\n"));
}
