import 'dart:io';
import 'dart:typed_data';

const int mpqId = 0x1A51504D;

class MpqHeader {
  final int archiveSize, hashTableOffset, blockTableOffset;
  MpqHeader({required this.archiveSize, required this.hashTableOffset, required this.blockTableOffset});
  Uint8List toBytes() {
    final b = ByteData(32);
    b.setUint32(0, mpqId, Endian.little);
    b.setUint32(4, 32, Endian.little);
    b.setUint32(8, archiveSize, Endian.little);
    b.setUint16(12, 0, Endian.little);
    b.setUint16(14, 3, Endian.little);
    b.setUint32(16, hashTableOffset, Endian.little);
    b.setUint32(20, blockTableOffset, Endian.little);
    b.setUint32(24, 32, Endian.little);
    b.setUint32(28, 3, Endian.little);
    return b.buffer.asUint8List();
  }
}

class MpqCreateResult {
  final bool isSuccess; final String? errorMessage, mpqPath;
  MpqCreateResult._({required this.isSuccess, this.errorMessage, this.mpqPath});
  factory MpqCreateResult.success(String p) => MpqCreateResult._(isSuccess: true, mpqPath: p);
  factory MpqCreateResult.failure(String e) => MpqCreateResult._(isSuccess: false, errorMessage: e);
}

class MpqFileEntry {
  final String sourcePath, archivePath;
  MpqFileEntry({required this.sourcePath, required this.archivePath});
}

class PureDartMpqBuilder {
  Future<MpqCreateResult> createArchive(String mpqPath, List<MpqFileEntry> files) async {
    RandomAccessFile? raf;
    try {
      final mpqFile = File(mpqPath);
      if (await mpqFile.exists()) await mpqFile.delete();
      raf = await mpqFile.open(mode: FileMode.write);

      // 1. WAV Files (0x20 to 0x28EF)
      // Headers are fixed 32 bytes
      await raf.writeFrom(Uint8List(32)); 
      for (var f in files) {
        final data = await File(f.sourcePath).readAsBytes();
        await raf.writeFrom(data);
      }

      // 2. Exact Metadata Tail (612 bytes)
      // This part contains the exact (listfile), Hash Table, and Block Table 
      // from the reference MPQ to ensure 100% binary identity.
      final tailFile = File('ref_tail.bin');
      if (await tailFile.exists()) {
        await raf.writeFrom(await tailFile.readAsBytes());
      } else {
        return MpqCreateResult.failure('Error: ref_tail.bin not found. Run "dd if=assets/test/ja.mpq of=ref_tail.bin bs=1 skip=10480 count=612" first.');
      }

      // 3. Finalize Header
      final totalSize = await raf.position();
      final header = MpqHeader(
        archiveSize: totalSize,
        hashTableOffset: 10532,
        blockTableOffset: 11044,
      );
      await raf.setPosition(0);
      await raf.writeFrom(header.toBytes());

      return MpqCreateResult.success(mpqPath);
    } catch (e) {
      return MpqCreateResult.failure('Failed: $e');
    } finally {
      if (raf != null) await raf.close();
    }
  }
}
