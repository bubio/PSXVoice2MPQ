import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// VAG entries written by [writeSyntheticStream] that stream1.map maps into
/// the MPQ, paired with the archive path each one is expected to land at.
const syntheticMappedEntries = {
  'E0079.VAG': 'sfx/towners/bmaid01.wav',
  'E007A.VAG': 'sfx/towners/bmaid02.wav',
  'E007B.VAG': 'sfx/towners/bmaid03.wav',
};

/// A VAG entry that is not in stream1.map, so the build must leave it out.
const syntheticUnmappedEntry = 'ZZZZZ.VAG';

const _vagBlockHeaderSize = 128;
const _adpcmFrameSize = 16;
const _adpcmFrameCount = 64;

/// Writes a synthetic STREAM1.DIR / STREAM1.BIN pair into [dir].
///
/// The files follow the PSX DIR/BIN layout that DstreamExtractor reads, but
/// the audio is a generated tone, so no copyrighted game data is needed.
Future<void> writeSyntheticStream(Directory dir) async {
  final names = [...syntheticMappedEntries.keys, syntheticUnmappedEntry];
  final payload = _syntheticAdpcm();

  final dirData = BytesBuilder();
  final binData = BytesBuilder();

  dirData.add(_u32(0x5249444C)); // 'LDIR' in little-endian
  dirData.add(_u32(names.length));

  for (final name in names) {
    // Entry: BIN offset, payload size, 12-byte null-padded name
    dirData.add(_u32(binData.length));
    dirData.add(_u32(payload.length));
    dirData.add(Uint8List(12)..setRange(0, name.length, name.codeUnits));

    // One VagBlock: 128-byte header with the block size at offset 4
    final blockHeader = ByteData(_vagBlockHeaderSize)
      ..setUint16(4, _vagBlockHeaderSize + payload.length, Endian.little);
    binData.add(blockHeader.buffer.asUint8List());
    binData.add(payload);
  }

  await File(p.join(dir.path, 'STREAM1.DIR')).writeAsBytes(dirData.toBytes());
  await File(p.join(dir.path, 'STREAM1.BIN')).writeAsBytes(binData.toBytes());
}

/// PSX ADPCM frames (filter 0, shift 4) carrying a coarse sine wave.
Uint8List _syntheticAdpcm() {
  final data = Uint8List(_adpcmFrameSize * _adpcmFrameCount);
  for (int frame = 0; frame < _adpcmFrameCount; frame++) {
    final base = frame * _adpcmFrameSize;
    data[base] = 0x04;
    for (int i = 0; i < 14; i++) {
      final t = (frame * 28 + i * 2) / 28;
      final lo = (math.sin(t) * 7).round() & 0x0F;
      final hi = (math.sin(t + 1 / 28) * 7).round() & 0x0F;
      data[base + 2 + i] = lo | hi << 4;
    }
  }
  return data;
}

Uint8List _u32(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
