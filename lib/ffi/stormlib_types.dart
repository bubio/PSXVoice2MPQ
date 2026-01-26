/// StormLib constants and flags for MPQ archive operations.
library;

/// MPQ archive creation flags for SFileCreateArchive.
class MpqCreateFlags {
  MpqCreateFlags._();

  /// Create archive of version 1 (up to 4 GB).
  static const int mpqCreateArchiveV1 = 0x00000000;

  /// Create archive of version 2 (larger than 4 GB).
  static const int mpqCreateArchiveV2 = 0x01000000;

  /// Create archive of version 3 (same as V2).
  static const int mpqCreateArchiveV3 = 0x02000000;

  /// Create archive of version 4 (same as V2).
  static const int mpqCreateArchiveV4 = 0x03000000;
}

/// File addition flags for SFileAddFileEx.
class MpqFileFlags {
  MpqFileFlags._();

  /// The file is imploded (PKWARE Data Compression Library).
  static const int mpqFileImplode = 0x00000100;

  /// The file is compressed.
  static const int mpqFileCompress = 0x00000200;

  /// The file is encrypted.
  static const int mpqFileEncrypted = 0x00010000;

  /// The file encryption key is adjusted by the block offset.
  static const int mpqFileFixKey = 0x00020000;

  /// The file is a deletion marker.
  static const int mpqFileDeleteMarker = 0x02000000;

  /// The file has CRC for each sector.
  static const int mpqFileSectorCrc = 0x04000000;

  /// Replace an existing file.
  static const int mpqFileReplaceExisting = 0x80000000;
}

/// Compression types for SFileAddFileEx.
class MpqCompression {
  MpqCompression._();

  /// No compression.
  static const int mpqCompressionNone = 0x00;

  /// Huffman compression (used on wave files only).
  static const int mpqCompressionHuffman = 0x01;

  /// ZLIB (Deflate) compression.
  static const int mpqCompressionZlib = 0x02;

  /// PKWare DCL compression.
  static const int mpqCompressionPkware = 0x08;

  /// BZip2 compression (added in Warcraft III).
  static const int mpqCompressionBzip2 = 0x10;

  /// LZMA compression (added in Starcraft II).
  static const int mpqCompressionLzma = 0x12;

  /// Sparse compression (added in Starcraft II).
  static const int mpqCompressionSparse = 0x20;

  /// IMA ADPCM compression for wave files (mono).
  static const int mpqCompressionAdpcmMono = 0x40;

  /// IMA ADPCM compression for wave files (stereo).
  static const int mpqCompressionAdpcmStereo = 0x80;
}

/// Windows error codes.
class ErrorCodes {
  ErrorCodes._();

  /// The operation completed successfully.
  static const int errorSuccess = 0;

  /// The system cannot find the file specified.
  static const int errorFileNotFound = 2;

  /// Access is denied.
  static const int errorAccessDenied = 5;

  /// Not enough memory to complete the operation.
  static const int errorNotEnoughMemory = 8;

  /// The file exists.
  static const int errorAlreadyExists = 183;

  /// The file could not be found in the archive.
  static const int errorFileNotFoundInArchive = 1001;
}
