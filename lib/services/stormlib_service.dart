import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../ffi/stormlib_bindings.dart';
import '../ffi/stormlib_loader.dart';
import '../ffi/stormlib_types.dart';

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

  /// Path inside the MPQ archive (e.g., "data\\global\\sfx\\cursor\\cursor.wav").
  final String archivePath;

  const MpqFileEntry({
    required this.sourcePath,
    required this.archivePath,
  });
}

/// High-level service for creating MPQ archives using StormLib.
class StormLibService {
  StormLibBindings? _bindings;
  bool _initialized = false;

  /// Initialize the StormLib service.
  /// Returns true if the library was loaded successfully.
  bool initialize() {
    if (_initialized) {
      return _bindings != null;
    }

    _initialized = true;
    _bindings = StormLibLoader.getBindings();
    return _bindings != null;
  }

  /// Check if the StormLib FFI is available and ready to use.
  bool get isAvailable {
    if (!_initialized) {
      initialize();
    }
    return _bindings != null;
  }

  /// Get the path to the bundled StormLib library.
  String? get libraryPath => StormLibLoader.libraryPath;

  /// Create an MPQ archive with the specified files.
  ///
  /// [mpqPath] - Full path where the MPQ file will be created.
  /// [files] - List of files to add to the archive.
  /// [compression] - Compression type to use (default: none).
  ///
  /// Returns an [MpqCreateResult] indicating success or failure.
  MpqCreateResult createArchive(
    String mpqPath,
    List<MpqFileEntry> files, {
    int compression = MpqCompression.mpqCompressionNone,
  }) {
    if (!isAvailable) {
      return MpqCreateResult.failure('StormLib is not available');
    }

    final bindings = _bindings!;

    // Delete existing file if present
    final mpqFile = File(mpqPath);
    if (mpqFile.existsSync()) {
      try {
        mpqFile.deleteSync();
      } catch (e) {
        return MpqCreateResult.failure(
            'Failed to delete existing MPQ file: $e');
      }
    }

    // Allocate native memory for the archive handle
    final handlePtr = calloc<Pointer<Void>>();
    Pointer<Void>? archiveHandle;

    try {
      // Calculate max file count (add some buffer)
      final maxFileCount = files.length + 16;

      // Create the archive with error handling for FFI calls
      int createResult;
      try {
        createResult = bindings.sFileCreateArchive(
          mpqPath,
          MpqCreateFlags.mpqCreateArchiveV1,
          maxFileCount,
          handlePtr,
        );
      } catch (e) {
        return MpqCreateResult.failure(
            'FFI error during SFileCreateArchive: $e');
      }

      if (createResult == 0) {
        return MpqCreateResult.failure(
            'Failed to create MPQ archive: SFileCreateArchive returned false');
      }

      archiveHandle = handlePtr.value;

      // Add each file to the archive
      final failedFiles = <String>[];
      for (final file in files) {
        // Convert forward slashes to backslashes for MPQ compatibility
        final archiveName = file.archivePath.replaceAll('/', '\\');

        try {
          // Determine flags based on compression
          final flags = compression == MpqCompression.mpqCompressionNone
              ? 0
              : MpqFileFlags.mpqFileCompress;

          int addResult;
          try {
            addResult = bindings.sFileAddFileEx(
              archiveHandle,
              file.sourcePath,
              archiveName,
              flags,
              compression,
              compression,
            );
          } catch (e) {
            failedFiles.add('${file.archivePath} (FFI error: $e)');
            continue;
          }

          if (addResult == 0) {
            failedFiles.add(file.archivePath);
          }
        } catch (e) {
          failedFiles.add('${file.archivePath} (error: $e)');
        }
      }

      // Note: SFileCompactArchive is skipped as it can cause issues on Windows
      // and is not strictly necessary for newly created archives

      // Close the archive
      int closeResult;
      try {
        closeResult = bindings.sFileCloseArchive(archiveHandle);
      } catch (e) {
        return MpqCreateResult.failure('FFI error during SFileCloseArchive: $e');
      }
      archiveHandle = null; // Mark as closed

      if (closeResult == 0) {
        return MpqCreateResult.failure('Failed to close MPQ archive properly');
      }

      if (failedFiles.isNotEmpty && failedFiles.length == files.length) {
        return MpqCreateResult.failure(
            'All files failed to add to archive');
      }

      return MpqCreateResult.success(mpqPath);
    } catch (e) {
      // Ensure archive is closed on unexpected errors
      if (archiveHandle != null) {
        try {
          bindings.sFileCloseArchive(archiveHandle);
        } catch (_) {
          // Ignore close errors during cleanup
        }
      }
      return MpqCreateResult.failure('Unexpected error: $e');
    } finally {
      calloc.free(handlePtr);
    }
  }
}
