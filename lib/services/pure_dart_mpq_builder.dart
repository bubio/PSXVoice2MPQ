import 'dart:io';
import 'dart:typed_data';

import 'dart:io';
import 'dart:typed_data';

// --- MPQ Format Constants ---

/// Magic string for MPQ archives ('MPQ\x1A').
const int mpqId = 0x1A51504D;
/// Size of the MPQ format version 1 header in bytes.
const int mpqHeaderSizeV1 = 32;
/// Size of a hash table entry in bytes.
const int mpqHashTableEntrySize = 16;
/// Size of a block table entry in bytes.
const int mpqBlockTableEntrySize = 16;

// --- Data Structures ---

/// Represents the header of an MPQ archive.
class MpqHeader {
  /// (4 bytes) Magic identifier, must be 'MPQ\x1A'.
  final int id;
  /// (4 bytes) Size of the MPQ header.
  final int headerSize;
  /// (4 bytes) Total size of the MPQ archive.
  final int archiveSize;
  /// (2 bytes) MPQ format version.
  final int formatVersion;  // 0=Format 1, 1=Format 2, 2=Format 3, 3=Format 4
  final int wBlockSize;       // Power of two exponent for logical sector size (512 * 2^wBlockSize)
  /// (2 bytes) Power of two of the hash table size.

  /// (4 bytes) Offset to the hash table.
  final int hashTableOffset;
  /// (4 bytes) Offset to the block table.
  final int blockTableOffset;
  /// (4 bytes) Number of entries in the hash table.
  final int hashTableEntries;
  /// (4 bytes) Number of entries in the block table.
  final int blockTableEntries;

  MpqHeader({
    required this.id,
    required this.headerSize,
    required this.archiveSize,
    required this.formatVersion,
    required this.wBlockSize,
    required this.hashTableOffset,
    required this.blockTableOffset,
    required this.hashTableEntries,
    required this.blockTableEntries,
  });

  /// Serializes the header to a byte buffer.
  Uint8List toBytes() {
    final buffer = ByteData(headerSize);
    int offset = 0;
    buffer.setUint32(offset, id, Endian.little);
    offset += 4;
    buffer.setUint32(offset, headerSize, Endian.little);
    offset += 4;
    buffer.setUint32(offset, archiveSize, Endian.little);
    offset += 4;
    buffer.setUint16(offset, formatVersion, Endian.little);
    offset += 2;
    buffer.setUint16(offset, wBlockSize, Endian.little);
    offset += 2;
    buffer.setUint32(offset, hashTableOffset, Endian.little);
    offset += 4;
    buffer.setUint32(offset, blockTableOffset, Endian.little);
    offset += 4;
    buffer.setUint32(offset, hashTableEntries, Endian.little);
    offset += 4;
    buffer.setUint32(offset, blockTableEntries, Endian.little);
    return buffer.buffer.asUint8List();
  }
}

/// Represents an entry in the MPQ hash table.
class MpqHashTableEntry {
  /// (4 bytes) The hash of the file path, part A.
  final int pathHashA;
  /// (4 bytes) The hash of the file path, part B.
  final int pathHashB;
  /// (2 bytes) The language of the file.
  final int locale;
  /// (2 bytes) The platform of the file.
  final int platform;
  /// (4 bytes) Index into the block table. If -1, the entry is empty.
  final int blockIndex;

  MpqHashTableEntry({
    required this.pathHashA,
    required this.pathHashB,
    this.locale = 0,
    this.platform = 0,
    required this.blockIndex,
  });

  /// Serializes the entry to a byte buffer.
  Uint8List toBytes() {
    final buffer = ByteData(mpqHashTableEntrySize);
    int offset = 0;
    buffer.setUint32(offset, pathHashA, Endian.little);
    offset += 4;
    buffer.setUint32(offset, pathHashB, Endian.little);
    offset += 4;
    buffer.setUint16(offset, locale, Endian.little);
    offset += 2;
    buffer.setUint16(offset, platform, Endian.little);
    offset += 2;
    buffer.setUint32(offset, blockIndex, Endian.little);
    return buffer.buffer.asUint8List();
  }
}

/// Represents an entry in the MPQ block table.
class MpqBlockTableEntry {
  /// (4 bytes) Offset of the file data within the archive.
  final int fileOffset;
  /// (4 bytes) Compressed size of the file data.
  final int compressedSize;
  /// (4 bytes) Uncompressed size of the file.
  final int uncompressedSize;
  /// (4 bytes) File flags.
  final int flags;

  MpqBlockTableEntry({
    required this.fileOffset,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.flags,
  });

  /// Serializes the entry to a byte buffer.
  Uint8List toBytes() {
    final buffer = ByteData(mpqBlockTableEntrySize);
    int offset = 0;
    buffer.setUint32(offset, fileOffset, Endian.little);
    offset += 4;
    buffer.setUint32(offset, compressedSize, Endian.little);
    offset += 4;
    buffer.setUint32(offset, uncompressedSize, Endian.little);
    offset += 4;
    buffer.setUint32(offset, flags, Endian.little);
    return buffer.buffer.asUint8List();
  }
}

// Note: These classes are defined here for now.
// They mirror the ones in stormlib_service.dart for easy replacement.

enum _MpqHashType {
  tableOffset,
  nameA,
  nameB,
}

/// Handles MPQ string hashing.
class _MpqHasher {
  static final Uint32List _encryptionTable = _prepareEncryptionTable();

  // Make cryptTable accessible for encryption
  static Uint32List get encryptionTable => _encryptionTable;

  static Uint32List _prepareEncryptionTable() {
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

  /// Hashes a file path string using the specified hash type.
  static int hashString(String filePath, _MpqHashType hashType) {
    int seed1 = 0x7FED7FED;
    int seed2 = 0xEEEEEEEE;
    int type;

    switch (hashType) {
      case _MpqHashType.tableOffset:
        type = 0;
        break;
      case _MpqHashType.nameA:
        type = 1;
        break;
      case _MpqHashType.nameB:
        type = 2;
        break;
    }

    final upperPath = filePath.replaceAll('/', '\\').toUpperCase();

    for (int i = 0; i < upperPath.length; i++) {
      final charCode = upperPath.codeUnitAt(i);
      final value = _encryptionTable[(type << 8) + charCode];

      seed1 = (value ^ (seed1 + seed2)).toUnsigned(32);
      seed2 = (charCode + seed1 + seed2 + (seed2 << 5) + 3).toUnsigned(32);
    }
    return seed1;
  }
}

/// Handles MPQ table encryption/decryption.
class _MpqEncryptor {
  // Port of DecryptBlock (which is symmetric, so can be used for EncryptBlock)
  static Uint8List encryptDecryptMpqBlock(Uint8List data, int key) {
    // MPQ encryption works on 32-bit unsigned integers (DWORDs)
    final Uint32List block = Uint32List.view(data.buffer);
    int length = block.length;

    int seed = 0xEEEEEEEE;
    int currentKey = key; // Use a mutable variable for key

    for (int i = 0; i < length; i++) {
      // seed += cryptTable[0x400 + (key & 0xFF)];
      seed = (seed + _MpqHasher.encryptionTable[0x400 + (currentKey & 0xFF)]).toUnsigned(32);
      int ch = block[i] ^ (currentKey + seed);

      // key = ((~key << 0x15) + 0x11111111) | (key >> 0x0B);
      currentKey = (((~currentKey & 0xFFFFFFFF) << 0x15) | (currentKey >> 0x0B)).toUnsigned(32);
      currentKey = (currentKey + 0x11111111).toUnsigned(32);

      seed = (ch + seed + (seed << 5) + 3).toUnsigned(32);
      block[i] = ch;
    }
    return data; // Return the modified original Uint8List
  }

  // Helper to derive initial key from key string
  // This is often HashString(keyString, HASH_OFFSET) or similar,
  // but for actual encryption, Blizzard uses known hardcoded keys.
  // The common fixed keys are:
  // Hash Table: 0xC3E57F40
  // Block Table: 0xBBF107CE
  // From StormLib sources, these keys are used.
  static const int _hashTableEncryptionKey = 0xC3E57F40;
  static const int _blockTableEncryptionKey = 0xBBF107CE;

  static int getHashTableEncryptionKey() => _hashTableEncryptionKey;
  static int getBlockTableEncryptionKey() => _blockTableEncryptionKey;
}



/// Result of an MPQ archive creation operation.
class MpqCreateResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? mpqPath;

  const MpqCreateResult._({
    required this.isSuccess,
    this.errorMessage,
    this.mpqPath,
  });

  factory MpqCreateResult.success(String mpqPath) {
    return MpqCreateResult._(isSuccess: true, mpqPath: mpqPath);
  }

  factory MpqCreateResult.failure(String errorMessage) {
    return MpqCreateResult._(isSuccess: false, errorMessage: errorMessage);
  }
}

/// File entry for adding to an MPQ archive.
class MpqFileEntry {
  /// Full path to the source file on disk.
  final String sourcePath;

  /// Path inside the MPQ archive (e.g., "data\global\sfx\cursor\cursor.wav").
  final String archivePath;

  const MpqFileEntry({
    required this.sourcePath,
    required this.archivePath,
  });
}

/// Pure Dart service for creating MPQ archives.
/// This is intended to replace the FFI-based StormLibService.
class PureDartMpqBuilder {
  /// Create an MPQ archive with the specified files.
  ///
  /// [mpqPath] - Full path where the MPQ file will be created.
  /// [files] - List of files to add to the archive.
  ///
  /// Returns an [MpqCreateResult] indicating success or failure.
  Future<MpqCreateResult> createArchive(
    String mpqPath,
    List<MpqFileEntry> files,
  ) async {
    RandomAccessFile? raf;
    try {
      final mpqFile = File(mpqPath);
      if (await mpqFile.exists()) {
        await mpqFile.delete();
      }
      raf = await mpqFile.open(mode: FileMode.write);

      // 1. Calculate table sizes, including the implicit (listfile)
      final actualFileCount = files.length;
      final totalEntries = actualFileCount + 1; // +1 for the (listfile)

      int hashTableSizePower = 0;
      while ((1 << hashTableSizePower) < totalEntries) {
        hashTableSizePower++;
      }
      final hashTableSize = 1 << hashTableSizePower;

      // 2. Prepare initial hash table
      final hashTable = List.generate(
        hashTableSize,
        (_) => MpqHashTableEntry(
          pathHashA: 0,
          pathHashB: 0,
          locale: 0,
          platform: 0,
          blockIndex: 0xFFFFFFFF, // -1 indicates an empty entry
        ),
      );
      final blockTable = <MpqBlockTableEntry>[];

      // 3. Write placeholder header and reserve space for tables
      final int headerAndTablesSize = mpqHeaderSizeV1 +
          (hashTableSize * mpqHashTableEntrySize) +
          (totalEntries * mpqBlockTableEntrySize); // Use totalEntries here

      await raf.setPosition(headerAndTablesSize);
      int currentFileOffset = headerAndTablesSize;

      // 4. Add (listfile) first
      final listFileEntry = MpqFileEntry(
        sourcePath: 'N/A', // Not a real file on disk
        archivePath: '(listfile)',
      );
      final listFileBytes = Uint8List(0); // Empty (listfile) for now

      // Write (listfile) content (empty)
      await raf.writeFrom(listFileBytes);

      // Create block entry for (listfile)
      const listFileFlags = 0x80000000; // MPQ_FILE_SINGLE_UNIT
      final listFileBlockEntry = MpqBlockTableEntry(
        fileOffset: currentFileOffset,
        compressedSize: listFileBytes.length,
        uncompressedSize: listFileBytes.length,
        flags: listFileFlags,
      );
      blockTable.add(listFileBlockEntry);
      currentFileOffset += listFileBytes.length;

      // Create hash entry for (listfile)
      final listFileHashA = _MpqHasher.hashString('(listfile)', _MpqHashType.nameA);
      final listFileHashB = _MpqHasher.hashString('(listfile)', _MpqHashType.nameB);
      final listFileHashIndex = _MpqHasher.hashString('(listfile)', _MpqHashType.tableOffset) % hashTableSize;

      int currentListFileHashIndex = listFileHashIndex;
      while (hashTable[currentListFileHashIndex].blockIndex != 0xFFFFFFFF) {
        currentListFileHashIndex = (currentListFileHashIndex + 1) % hashTableSize;
      }

      hashTable[currentListFileHashIndex] = MpqHashTableEntry(
        pathHashA: listFileHashA,
        pathHashB: listFileHashB,
        blockIndex: 0, // Block index 0 is for (listfile)
      );

      // 5. Add each actual file
      for (int i = 0; i < actualFileCount; i++) {
        final fileEntry = files[i];
        final fileBytes = await File(fileEntry.sourcePath).readAsBytes();

        // Write file content
        await raf.writeFrom(fileBytes);

        // Create block entry
        const flags = 0x80000000; // File is a single unit
        final blockEntry = MpqBlockTableEntry(
          fileOffset: currentFileOffset,
          compressedSize: fileBytes.length,
          uncompressedSize: fileBytes.length,
          flags: flags,
        );
        blockTable.add(blockEntry);
        currentFileOffset += fileBytes.length;

        // Create hash entry
        final archivePath = fileEntry.archivePath;
        final hashA = _MpqHasher.hashString(archivePath, _MpqHashType.nameA);
        final hashB = _MpqHasher.hashString(archivePath, _MpqHashType.nameB);
        final hashIndex = _MpqHasher.hashString(archivePath, _MpqHashType.tableOffset) % hashTableSize;

        // Find an empty slot using linear probing
        int currentHashIndex = hashIndex;
        while (hashTable[currentHashIndex].blockIndex != 0xFFFFFFFF) {
          currentHashIndex = (currentHashIndex + 1) % hashTableSize;
        }

        hashTable[currentHashIndex] = MpqHashTableEntry(
          pathHashA: hashA,
          pathHashB: hashB,
          blockIndex: i + 1, // Block index for actual files start from 1
        );
      }

      final int archiveSize = await raf.position();

      // 6. Write final tables
      final int hashTableOffset = mpqHeaderSizeV1;
      final int blockTableOffset = hashTableOffset + (hashTableSize * mpqHashTableEntrySize);

      // Write hash table
      await raf.setPosition(hashTableOffset);
      final hashTableBytes = ByteData(hashTableSize * mpqHashTableEntrySize);
      for (int i = 0; i < hashTableSize; i++) {
        hashTableBytes.buffer
            .asUint8List()
            .setAll(i * mpqHashTableEntrySize, hashTable[i].toBytes());
      }
      _MpqEncryptor.encryptDecryptMpqBlock(hashTableBytes.buffer.asUint8List(), _MpqEncryptor.getHashTableEncryptionKey()); // Encrypt
      await raf.writeFrom(hashTableBytes.buffer.asUint8List());

      // Write block table
      await raf.setPosition(blockTableOffset);
      final blockTableBytes = ByteData(totalEntries * mpqBlockTableEntrySize); // Use totalEntries here
      for (int i = 0; i < totalEntries; i++) {
        blockTableBytes.buffer
            .asUint8List()
            .setAll(i * mpqBlockTableEntrySize, blockTable[i].toBytes());
      }
      _MpqEncryptor.encryptDecryptMpqBlock(blockTableBytes.buffer.asUint8List(), _MpqEncryptor.getBlockTableEncryptionKey()); // Encrypt
      await raf.writeFrom(blockTableBytes.buffer.asUint8List());

      // 7. Write final header
      final header = MpqHeader(
        id: mpqId,
        headerSize: mpqHeaderSizeV1,
        archiveSize: archiveSize,
        formatVersion: 0,
        wBlockSize: 3, // Default for 4KB sectors
        hashTableOffset: hashTableOffset,
        blockTableOffset: blockTableOffset,
        hashTableEntries: hashTableSize, // Use calculated hashTableSize for entries
        blockTableEntries: totalEntries,
      );
      await raf.setPosition(0);
      await raf.writeFrom(header.toBytes());

      // 8. Close file
      await raf.close();
      raf = null;

      return MpqCreateResult.success(mpqPath);
    } catch (e) {
      return MpqCreateResult.failure('Failed to create archive: $e');
    } finally {
      await raf?.close();
    }
  }
}
