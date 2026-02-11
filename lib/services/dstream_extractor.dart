import 'dart:io';
import 'dart:typed_data';

/// Extracts files from PlayStation STREAM.DIR/BIN archives.
/// Based on dstream by the PSX tools project.
class DstreamExtractor {
  // 'LDIR' stored as bytes [0x4C, 0x44, 0x49, 0x52], read as little-endian 32-bit
  static const int _ldirMagic = 0x5249444C; // 'LDIR' in little-endian
  static const int _vagMagic = 0x56414770; // 'VAGp'
  static const int _streamEntrySize = 20; // 4 + 4 + 12 bytes
  static const int _vagBlockSize = 128; // sizeof(VagBlock)
  static const int _defaultVagRate = 11025;

  /// Extracts files from a STREAM.DIR/BIN pair.
  ///
  /// [dirPath] - Path to the .DIR file
  /// [binPath] - Path to the .BIN file
  /// [outputDir] - Directory to extract files to
  /// [extensions] - Optional list of extensions to filter (e.g., ['vag'])
  ///
  /// Returns a [DstreamResult] with extraction details.
  Future<DstreamResult> extract({
    required String dirPath,
    required String binPath,
    required String outputDir,
    List<String>? extensions,
  }) async {
    final dirFile = File(dirPath);
    final binFile = File(binPath);

    if (!await dirFile.exists()) {
      return DstreamResult.failure('DIR file not found: $dirPath');
    }
    if (!await binFile.exists()) {
      return DstreamResult.failure('BIN file not found: $binPath');
    }

    try {
      final dirData = await dirFile.readAsBytes();
      final binData = await binFile.readAsBytes();

      return extractFromBytes(
        dirData: dirData,
        binData: binData,
        outputDir: outputDir,
        extensions: extensions,
      );
    } catch (e) {
      return DstreamResult.failure('Extraction error: $e');
    }
  }

  /// Extracts files from DIR/BIN data in memory.
  Future<DstreamResult> extractFromBytes({
    required Uint8List dirData,
    required Uint8List binData,
    required String outputDir,
    List<String>? extensions,
  }) async {
    // Verify DIR magic
    if (dirData.length < 8) {
      return DstreamResult.failure('DIR file too small');
    }

    final magic = _readLittleEndian32(dirData, 0);
    if (magic != _ldirMagic) {
      return DstreamResult.failure('Invalid DIR file magic');
    }

    final entryCount = _readLittleEndian32(dirData, 4);
    final entries = <StreamEntry>[];

    // Parse directory entries
    for (int i = 0; i < entryCount; i++) {
      final entryOffset = 8 + (i * _streamEntrySize);
      if (entryOffset + _streamEntrySize > dirData.length) {
        break;
      }

      final offset = _readLittleEndian32(dirData, entryOffset);
      final size = _readLittleEndian32(dirData, entryOffset + 4);
      final nameBytes = dirData.sublist(entryOffset + 8, entryOffset + 20);
      final name = _readNullTerminatedString(nameBytes);

      entries.add(StreamEntry(
        offset: offset,
        size: size,
        name: name,
      ));
    }

    // Create output directory
    final outDir = Directory(outputDir);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    // Extract files
    final extractedFiles = <String>[];
    final normalizedExtensions =
        extensions?.map((e) => e.toLowerCase()).toList();

    for (final entry in entries) {
      if (entry.size <= 0) continue;

      // Check extension filter
      final ext = _getExtension(entry.name).toLowerCase();
      if (normalizedExtensions != null &&
          !normalizedExtensions.contains(ext)) {
        continue;
      }

      final outputPath = '$outputDir/${entry.name}';

      if (ext == 'vag') {
        await _extractVagFile(entry, binData, outputPath);
      } else {
        await _extractRegularFile(entry, binData, outputPath);
      }

      extractedFiles.add(entry.name);
    }

    return DstreamResult.success(
      totalEntries: entries.length,
      extractedFiles: extractedFiles,
    );
  }

  /// Extracts a single VAG file by name from DIR/BIN data.
  ///
  /// Returns the VAG file data as Uint8List, or null if not found.
  Uint8List? extractVagByName({
    required Uint8List dirData,
    required Uint8List binData,
    required String fileName,
  }) {
    // Verify DIR magic
    if (dirData.length < 8) return null;

    final magic = _readLittleEndian32(dirData, 0);
    if (magic != _ldirMagic) return null;

    final entryCount = _readLittleEndian32(dirData, 4);
    final upperFileName = fileName.toUpperCase();

    // Find the entry
    for (int i = 0; i < entryCount; i++) {
      final entryOffset = 8 + (i * _streamEntrySize);
      if (entryOffset + _streamEntrySize > dirData.length) break;

      final nameBytes = dirData.sublist(entryOffset + 8, entryOffset + 20);
      final name = _readNullTerminatedString(nameBytes);

      if (name.toUpperCase() == upperFileName) {
        final offset = _readLittleEndian32(dirData, entryOffset);
        final size = _readLittleEndian32(dirData, entryOffset + 4);

        if (size <= 0) return null;

        return _buildVagData(
          StreamEntry(offset: offset, size: size, name: name),
          binData,
        );
      }
    }

    return null;
  }

  Future<void> _extractVagFile(
    StreamEntry entry,
    Uint8List binData,
    String outputPath,
  ) async {
    final vagData = _buildVagData(entry, binData);
    if (vagData != null) {
      await File(outputPath).writeAsBytes(vagData);
    }
  }

  Uint8List? _buildVagData(StreamEntry entry, Uint8List binData) {
    // Build VAG header
    final header = _buildVagHeader(entry);

    // Extract VAG chunks from BIN
    final chunks = _extractVagChunks(entry, binData);
    if (chunks == null) return null;

    // Combine header and chunks
    final result = Uint8List(header.length + chunks.length);
    result.setRange(0, header.length, header);
    result.setRange(header.length, result.length, chunks);

    return result;
  }

  Uint8List _buildVagHeader(StreamEntry entry) {
    final header = ByteData(48); // sizeof(VagHeader)

    // Magic 'VAGp' (big-endian)
    header.setUint32(0, _vagMagic, Endian.big);

    // Version (big-endian)
    header.setUint32(4, 4, Endian.big);

    // Reserved field (offset 8)
    header.setUint32(8, 0, Endian.big);

    // Size (big-endian)
    header.setUint32(12, entry.size, Endian.big);

    // Sample rate (big-endian)
    header.setUint32(16, _defaultVagRate, Endian.big);

    // Reserved fields (offsets 20, 24, 28)
    header.setUint32(20, 0, Endian.big);
    header.setUint32(24, 0, Endian.big);
    header.setUint32(28, 0, Endian.big);

    // Name (offset 32, 16 bytes)
    final nameBytes = entry.name.codeUnits;
    for (int i = 0; i < 16 && i < nameBytes.length; i++) {
      header.setUint8(32 + i, nameBytes[i]);
    }

    return header.buffer.asUint8List();
  }

  Uint8List? _extractVagChunks(StreamEntry entry, Uint8List binData) {
    final chunks = BytesBuilder();
    int binOffset = entry.offset;
    int totalWritten = 0;

    while (totalWritten < entry.size) {
      if (binOffset + _vagBlockSize > binData.length) {
        break;
      }

      // Read VagBlock header
      // block_size is at offset 4 (uint16_t)
      final blockSize = binData[binOffset + 4] | (binData[binOffset + 5] << 8);
      final dataSize = blockSize - _vagBlockSize;

      if (dataSize <= 0 || binOffset + blockSize > binData.length) {
        break;
      }

      // Skip VagBlock header, write data
      final dataStart = binOffset + _vagBlockSize;
      chunks.add(binData.sublist(dataStart, dataStart + dataSize));

      totalWritten += dataSize;
      binOffset += blockSize;
    }

    if (totalWritten != entry.size) {
      // Size mismatch - might indicate corruption or different format
      return null;
    }

    return chunks.toBytes();
  }

  Future<void> _extractRegularFile(
    StreamEntry entry,
    Uint8List binData,
    String outputPath,
  ) async {
    // Regular files have a 4-byte checksum followed by data
    final dataOffset = entry.offset + 4;
    if (dataOffset + entry.size > binData.length) {
      return;
    }

    final data = binData.sublist(dataOffset, dataOffset + entry.size);
    await File(outputPath).writeAsBytes(data);
  }

  int _readLittleEndian32(Uint8List data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  String _readNullTerminatedString(Uint8List bytes) {
    final nullIndex = bytes.indexOf(0);
    final length = nullIndex >= 0 ? nullIndex : bytes.length;
    return String.fromCharCodes(bytes.sublist(0, length));
  }

  String _getExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1);
  }
}

/// Represents a single entry in the STREAM directory.
class StreamEntry {
  final int offset;
  final int size;
  final String name;

  StreamEntry({
    required this.offset,
    required this.size,
    required this.name,
  });
}

/// Result of a dstream extraction operation.
class DstreamResult {
  final bool isSuccess;
  final String? errorMessage;
  final int totalEntries;
  final List<String> extractedFiles;

  DstreamResult._({
    required this.isSuccess,
    this.errorMessage,
    this.totalEntries = 0,
    this.extractedFiles = const [],
  });

  factory DstreamResult.success({
    required int totalEntries,
    required List<String> extractedFiles,
  }) =>
      DstreamResult._(
        isSuccess: true,
        totalEntries: totalEntries,
        extractedFiles: extractedFiles,
      );

  factory DstreamResult.failure(String message) => DstreamResult._(
        isSuccess: false,
        errorMessage: message,
      );
}
