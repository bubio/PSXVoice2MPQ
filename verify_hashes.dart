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

void decryptMpqBlock(Uint8List data, int key, Uint32List table) {
  final Uint32List block = Uint32List.view(data.buffer, data.offsetInBytes, data.length ~/ 4);
  int dwKey1 = key;
  int dwKey2 = 0xEEEEEEEE;

  for (int i = 0; i < block.length; i++) {
    dwKey2 = (dwKey2 + table[0x400 + (dwKey1 & 0xFF)]).toUnsigned(32);
    int dwValue32 = (block[i] ^ (dwKey1 + dwKey2)).toUnsigned(32);

    dwKey1 = ((((~dwKey1) & 0xFFFFFFFF) << 0x15) + 0x11111111).toUnsigned(32) | (dwKey1 >> 0x0B);
    dwKey1 = dwKey1.toUnsigned(32);
    
    dwKey2 = (dwValue32 + dwKey2 + (dwKey2 << 5) + 3).toUnsigned(32);
    block[i] = dwValue32;
  }
}

void main() async {
  final table = prepareEncryptionTable();
  final file = File('assets/test/ja.mpq');
  final bytes = await file.readAsBytes();
  
  // Try 0xC3AF3770 (calculated HashString("(hash table)", 3))
  final hashTableBytes = bytes.sublist(10532, 11044);
  decryptMpqBlock(hashTableBytes, 0xC3AF3770, table);
  
  final view = ByteData.view(hashTableBytes.buffer);
  print('Decrypted Hash Table (Key: 0xC3AF3770):');
  for (int i = 0; i < 32; i++) {
    final offset = i * 16;
    final blockIdx = view.getUint32(offset + 12, Endian.little);
    if (blockIdx != 0xFFFFFFFF) {
      final h1 = view.getUint32(offset, Endian.little);
      final h2 = view.getUint32(offset + 4, Endian.little);
      print('Index $i: HashA=0x${h1.toRadixString(16).toUpperCase()}, HashB=0x${h2.toRadixString(16).toUpperCase()}, BlockIdx=$blockIdx');
    }
  }
}