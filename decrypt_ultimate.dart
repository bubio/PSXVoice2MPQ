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
  final bytes = filePath.toUpperCase().codeUnits;
  for (int ch in bytes) {
    if (ch == 0x2F) ch = 0x5C; // Convert / to \
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
    dwKey2 = (cipher + dwKey2 + (dwKey2 << 5) + 3).toUnsigned(32);
    block[i] = plain;
  }
}

void main() async {
  final table = prepareEncryptionTable();
  final baseKey = hashString("(listfile)", 3, table);
  
  final file = File('assets/test/ja.mpq');
  final bytes = await file.readAsBytes();
  final data = bytes.sublist(10480, 10480 + 52);

  print('Base Key: 0x${baseKey.toRadixString(16).toUpperCase()}');

  final keys = {
    'baseKey': baseKey,
    'baseKey + offset': (baseKey + 10480).toUnsigned(32),
    '(baseKey + offset) ^ size': (baseKey + 10480).toUnsigned(32) ^ 52,
    'baseKey ^ size': baseKey ^ 52,
    'baseKey + 32': (baseKey + 32).toUnsigned(32),
    '(baseKey + 32) ^ size': (baseKey + 32).toUnsigned(32) ^ 52,
  };

  for (var entry in keys.entries) {
    final trial = Uint8List.fromList(data);
    decryptMpqBlock(trial, entry.value, table);
    print('\nTrial: ${entry.key} (0x${entry.value.toRadixString(16).toUpperCase()})');
    final result = trial.map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : ".").join("");
    print('Result: $result');
    print('Hex: ${trial.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
  }
}