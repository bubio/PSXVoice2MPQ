import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Platform-specific TCHAR type
// On Windows with UNICODE defined, TCHAR is wchar_t (UTF-16)
// On other platforms, TCHAR is char (UTF-8)

/// Native function type for SFileCreateArchive (ANSI version).
typedef SFileCreateArchiveNativeAnsi = Int32 Function(
  Pointer<Utf8> szMpqName,
  Uint32 dwCreateFlags,
  Uint32 dwMaxFileCount,
  Pointer<Pointer<Void>> phMpq,
);

/// Native function type for SFileCreateArchive (Unicode version).
typedef SFileCreateArchiveNativeWide = Int32 Function(
  Pointer<Utf16> szMpqName,
  Uint32 dwCreateFlags,
  Uint32 dwMaxFileCount,
  Pointer<Pointer<Void>> phMpq,
);

typedef SFileCreateArchiveDartAnsi = int Function(
  Pointer<Utf8> szMpqName,
  int dwCreateFlags,
  int dwMaxFileCount,
  Pointer<Pointer<Void>> phMpq,
);

typedef SFileCreateArchiveDartWide = int Function(
  Pointer<Utf16> szMpqName,
  int dwCreateFlags,
  int dwMaxFileCount,
  Pointer<Pointer<Void>> phMpq,
);

/// Native function type for SFileAddFileEx (ANSI version).
typedef SFileAddFileExNativeAnsi = Int32 Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szFileName,
  Pointer<Utf8> szArchivedName,
  Uint32 dwFlags,
  Uint32 dwCompression,
  Uint32 dwCompressionNext,
);

/// Native function type for SFileAddFileEx (Unicode version).
typedef SFileAddFileExNativeWide = Int32 Function(
  Pointer<Void> hMpq,
  Pointer<Utf16> szFileName,
  Pointer<Utf8> szArchivedName, // Archive name is always ANSI in MPQ
  Uint32 dwFlags,
  Uint32 dwCompression,
  Uint32 dwCompressionNext,
);

typedef SFileAddFileExDartAnsi = int Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szFileName,
  Pointer<Utf8> szArchivedName,
  int dwFlags,
  int dwCompression,
  int dwCompressionNext,
);

typedef SFileAddFileExDartWide = int Function(
  Pointer<Void> hMpq,
  Pointer<Utf16> szFileName,
  Pointer<Utf8> szArchivedName,
  int dwFlags,
  int dwCompression,
  int dwCompressionNext,
);

/// Native function type for SFileCloseArchive.
typedef SFileCloseArchiveNative = Int32 Function(Pointer<Void> hMpq);
typedef SFileCloseArchiveDart = int Function(Pointer<Void> hMpq);

/// Native function type for GetLastError (Windows).
typedef GetLastErrorNative = Uint32 Function();
typedef GetLastErrorDart = int Function();

/// Native function type for SFileSetMaxFileCount.
typedef SFileSetMaxFileCountNative = Int32 Function(
  Pointer<Void> hMpq,
  Uint32 dwMaxFileCount,
);
typedef SFileSetMaxFileCountDart = int Function(
  Pointer<Void> hMpq,
  int dwMaxFileCount,
);

/// Native function type for SFileCompactArchive (ANSI version).
typedef SFileCompactArchiveNativeAnsi = Int32 Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szListFile,
  Int32 bReserved,
);

/// Native function type for SFileCompactArchive (Unicode version).
typedef SFileCompactArchiveNativeWide = Int32 Function(
  Pointer<Void> hMpq,
  Pointer<Utf16> szListFile,
  Int32 bReserved,
);

typedef SFileCompactArchiveDartAnsi = int Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szListFile,
  int bReserved,
);

typedef SFileCompactArchiveDartWide = int Function(
  Pointer<Void> hMpq,
  Pointer<Utf16> szListFile,
  int bReserved,
);

/// FFI bindings for StormLib functions.
/// Handles platform-specific differences (ANSI vs Unicode).
class StormLibBindings {
  final DynamicLibrary _lib;
  final bool _useUnicode;

  // ANSI function pointers
  SFileCreateArchiveDartAnsi? _sFileCreateArchiveAnsi;
  SFileAddFileExDartAnsi? _sFileAddFileExAnsi;
  SFileCompactArchiveDartAnsi? _sFileCompactArchiveAnsi;

  // Unicode function pointers
  SFileCreateArchiveDartWide? _sFileCreateArchiveWide;
  SFileAddFileExDartWide? _sFileAddFileExWide;
  SFileCompactArchiveDartWide? _sFileCompactArchiveWide;

  // Common function pointers
  late final SFileCloseArchiveDart sFileCloseArchive;
  late final SFileSetMaxFileCountDart sFileSetMaxFileCount;
  late final GetLastErrorDart? getLastError;

  StormLibBindings(this._lib) : _useUnicode = Platform.isWindows {
    if (_useUnicode) {
      // Windows: Use Unicode versions
      _sFileCreateArchiveWide = _lib
          .lookup<NativeFunction<SFileCreateArchiveNativeWide>>(
              'SFileCreateArchive')
          .asFunction<SFileCreateArchiveDartWide>();

      _sFileAddFileExWide = _lib
          .lookup<NativeFunction<SFileAddFileExNativeWide>>('SFileAddFileEx')
          .asFunction<SFileAddFileExDartWide>();

      _sFileCompactArchiveWide = _lib
          .lookup<NativeFunction<SFileCompactArchiveNativeWide>>(
              'SFileCompactArchive')
          .asFunction<SFileCompactArchiveDartWide>();
    } else {
      // macOS/Linux: Use ANSI versions
      _sFileCreateArchiveAnsi = _lib
          .lookup<NativeFunction<SFileCreateArchiveNativeAnsi>>(
              'SFileCreateArchive')
          .asFunction<SFileCreateArchiveDartAnsi>();

      _sFileAddFileExAnsi = _lib
          .lookup<NativeFunction<SFileAddFileExNativeAnsi>>('SFileAddFileEx')
          .asFunction<SFileAddFileExDartAnsi>();

      _sFileCompactArchiveAnsi = _lib
          .lookup<NativeFunction<SFileCompactArchiveNativeAnsi>>(
              'SFileCompactArchive')
          .asFunction<SFileCompactArchiveDartAnsi>();
    }

    sFileCloseArchive = _lib
        .lookup<NativeFunction<SFileCloseArchiveNative>>('SFileCloseArchive')
        .asFunction<SFileCloseArchiveDart>();

    sFileSetMaxFileCount = _lib
        .lookup<NativeFunction<SFileSetMaxFileCountNative>>(
            'SFileSetMaxFileCount')
        .asFunction<SFileSetMaxFileCountDart>();

    // GetLastError is only available on Windows via kernel32.dll
    getLastError = null;
  }

  /// Create an MPQ archive.
  /// Handles platform-specific string encoding automatically.
  int sFileCreateArchive(
    String mpqName,
    int dwCreateFlags,
    int dwMaxFileCount,
    Pointer<Pointer<Void>> phMpq,
  ) {
    if (_useUnicode) {
      final namePtr = mpqName.toNativeUtf16();
      try {
        return _sFileCreateArchiveWide!(namePtr, dwCreateFlags, dwMaxFileCount, phMpq);
      } finally {
        calloc.free(namePtr);
      }
    } else {
      final namePtr = mpqName.toNativeUtf8();
      try {
        return _sFileCreateArchiveAnsi!(namePtr, dwCreateFlags, dwMaxFileCount, phMpq);
      } finally {
        calloc.free(namePtr);
      }
    }
  }

  /// Add a file to an MPQ archive.
  /// Handles platform-specific string encoding for the source file path.
  /// The archive name is always ANSI (MPQ internal format).
  int sFileAddFileEx(
    Pointer<Void> hMpq,
    String szFileName,
    String szArchivedName,
    int dwFlags,
    int dwCompression,
    int dwCompressionNext,
  ) {
    final archiveNamePtr = szArchivedName.toNativeUtf8();
    try {
      if (_useUnicode) {
        final fileNamePtr = szFileName.toNativeUtf16();
        try {
          return _sFileAddFileExWide!(
            hMpq,
            fileNamePtr,
            archiveNamePtr,
            dwFlags,
            dwCompression,
            dwCompressionNext,
          );
        } finally {
          calloc.free(fileNamePtr);
        }
      } else {
        final fileNamePtr = szFileName.toNativeUtf8();
        try {
          return _sFileAddFileExAnsi!(
            hMpq,
            fileNamePtr,
            archiveNamePtr,
            dwFlags,
            dwCompression,
            dwCompressionNext,
          );
        } finally {
          calloc.free(fileNamePtr);
        }
      }
    } finally {
      calloc.free(archiveNamePtr);
    }
  }

  /// Compact an MPQ archive.
  int sFileCompactArchive(
    Pointer<Void> hMpq,
    String? szListFile,
    int bReserved,
  ) {
    if (_useUnicode) {
      if (szListFile == null) {
        return _sFileCompactArchiveWide!(hMpq, nullptr.cast<Utf16>(), bReserved);
      }
      final listFilePtr = szListFile.toNativeUtf16();
      try {
        return _sFileCompactArchiveWide!(hMpq, listFilePtr, bReserved);
      } finally {
        calloc.free(listFilePtr);
      }
    } else {
      if (szListFile == null) {
        return _sFileCompactArchiveAnsi!(hMpq, nullptr.cast<Utf8>(), bReserved);
      }
      final listFilePtr = szListFile.toNativeUtf8();
      try {
        return _sFileCompactArchiveAnsi!(hMpq, listFilePtr, bReserved);
      } finally {
        calloc.free(listFilePtr);
      }
    }
  }
}
