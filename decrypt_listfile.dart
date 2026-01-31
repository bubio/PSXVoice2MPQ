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

int hashString(String filePath, int type, Uint32List encryptionTable) {
  int seed1 = 0x7FED7FED;
  int seed2 = 0xEEEEEEEE;
  final upperPath = filePath.replaceAll('/', '\\').toUpperCase();
  for (int i = 0; i < upperPath.length; i++) {
    final charCode = upperPath.codeUnitAt(i);
    final value = encryptionTable[(type << 8) + charCode];
    seed1 = (value ^ (seed1 + seed2)).toUnsigned(32);
    seed2 = (charCode + seed1 + seed2 + (seed2 << 5) + 3).toUnsigned(32);
  }
  return seed1;
}

void decryptMpqBlock(Uint8List data, int key, Uint32List encryptionTable) {
  final Uint32List block = Uint32List.view(data.buffer, data.offsetInBytes, data.length ~/ 4);
  int length = block.length;
  int seed = 0xEEEEEEEE;
  int currentKey = key;

  for (int i = 0; i < length; i++) {
    seed = (seed + encryptionTable[0x400 + (currentKey & 0xFF)]).toUnsigned(32);
    int cipher = block[i];
    int plain = (cipher ^ (currentKey + seed)).toUnsigned(32);
    
    int part1 = (((~currentKey) & 0xFFFFFFFF) << 0x15).toUnsigned(32);
    part1 = (part1 + 0x11111111).toUnsigned(32);
    int part2 = (currentKey >> 0x0B).toUnsigned(32);
    currentKey = (part1 | part2).toUnsigned(32);

    seed = (plain + seed + (seed << 5) + 3).toUnsigned(32);
    block[i] = plain;
  }
}

void main() async {
  final encryptionTable = prepareEncryptionTable();
  final baseKey = hashString("(listfile)", 3, encryptionTable);
  final file = File('assets/test/ja.mpq');
  final bytes = await file.readAsBytes();
  final listFileOffset = 10480;
  final encryptedData = bytes.sublist(listFileOffset, listFileOffset + 52);

  print('Base Key: 0x${baseKey.toRadixString(16).toUpperCase()}');

  // Attempt various key combinations
  final trials = {
    'baseKey': baseKey,
    'baseKey + offset': (baseKey + listFileOffset).toUnsigned(32),
    '(baseKey + offset) ^ size': (baseKey + listFileOffset).toUnsigned(32) ^ 52,
    'baseKey ^ size': baseKey ^ 52,
  };

  for (var entry in trials.entries) {
    final data = Uint8List.fromList(encryptedData);
    decryptMpqBlock(data, entry.value, encryptionTable);
    print('\nTrial: ${entry.key} (Key: 0x${entry.value.toRadixString(16).toUpperCase()})');
    final plain = String.fromCharCodes(data);
    print('Result String: ${plain.replaceAll("\r", "\\r").replaceAll("\n", "\\n")}');
    print('Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
  }
}
