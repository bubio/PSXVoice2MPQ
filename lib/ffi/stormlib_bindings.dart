import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Native function type for SFileCreateArchive.
/// bool SFileCreateArchive(
///   const TCHAR * szMpqName,
///   DWORD dwCreateFlags,
///   DWORD dwMaxFileCount,
///   HANDLE * phMpq
/// );
typedef SFileCreateArchiveNative = Int32 Function(
  Pointer<Utf8> szMpqName,
  Uint32 dwCreateFlags,
  Uint32 dwMaxFileCount,
  Pointer<Pointer<Void>> phMpq,
);
typedef SFileCreateArchiveDart = int Function(
  Pointer<Utf8> szMpqName,
  int dwCreateFlags,
  int dwMaxFileCount,
  Pointer<Pointer<Void>> phMpq,
);

/// Native function type for SFileAddFileEx.
/// bool SFileAddFileEx(
///   HANDLE hMpq,
///   const TCHAR * szFileName,
///   const char * szArchivedName,
///   DWORD dwFlags,
///   DWORD dwCompression,
///   DWORD dwCompressionNext
/// );
typedef SFileAddFileExNative = Int32 Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szFileName,
  Pointer<Utf8> szArchivedName,
  Uint32 dwFlags,
  Uint32 dwCompression,
  Uint32 dwCompressionNext,
);
typedef SFileAddFileExDart = int Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szFileName,
  Pointer<Utf8> szArchivedName,
  int dwFlags,
  int dwCompression,
  int dwCompressionNext,
);

/// Native function type for SFileCloseArchive.
/// bool SFileCloseArchive(HANDLE hMpq);
typedef SFileCloseArchiveNative = Int32 Function(Pointer<Void> hMpq);
typedef SFileCloseArchiveDart = int Function(Pointer<Void> hMpq);

/// Native function type for GetLastError (Windows).
/// DWORD GetLastError(void);
typedef GetLastErrorNative = Uint32 Function();
typedef GetLastErrorDart = int Function();

/// Native function type for SFileSetMaxFileCount.
/// bool SFileSetMaxFileCount(HANDLE hMpq, DWORD dwMaxFileCount);
typedef SFileSetMaxFileCountNative = Int32 Function(
  Pointer<Void> hMpq,
  Uint32 dwMaxFileCount,
);
typedef SFileSetMaxFileCountDart = int Function(
  Pointer<Void> hMpq,
  int dwMaxFileCount,
);

/// Native function type for SFileCompactArchive.
/// bool SFileCompactArchive(HANDLE hMpq, const TCHAR * szListFile, bool bReserved);
typedef SFileCompactArchiveNative = Int32 Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szListFile,
  Int32 bReserved,
);
typedef SFileCompactArchiveDart = int Function(
  Pointer<Void> hMpq,
  Pointer<Utf8> szListFile,
  int bReserved,
);

/// FFI bindings for StormLib functions.
class StormLibBindings {
  final DynamicLibrary _lib;

  late final SFileCreateArchiveDart sFileCreateArchive;
  late final SFileAddFileExDart sFileAddFileEx;
  late final SFileCloseArchiveDart sFileCloseArchive;
  late final SFileSetMaxFileCountDart sFileSetMaxFileCount;
  late final SFileCompactArchiveDart sFileCompactArchive;
  late final GetLastErrorDart? getLastError;

  StormLibBindings(this._lib) {
    sFileCreateArchive = _lib
        .lookup<NativeFunction<SFileCreateArchiveNative>>('SFileCreateArchive')
        .asFunction<SFileCreateArchiveDart>();

    sFileAddFileEx = _lib
        .lookup<NativeFunction<SFileAddFileExNative>>('SFileAddFileEx')
        .asFunction<SFileAddFileExDart>();

    sFileCloseArchive = _lib
        .lookup<NativeFunction<SFileCloseArchiveNative>>('SFileCloseArchive')
        .asFunction<SFileCloseArchiveDart>();

    sFileSetMaxFileCount = _lib
        .lookup<NativeFunction<SFileSetMaxFileCountNative>>(
            'SFileSetMaxFileCount')
        .asFunction<SFileSetMaxFileCountDart>();

    sFileCompactArchive = _lib
        .lookup<NativeFunction<SFileCompactArchiveNative>>(
            'SFileCompactArchive')
        .asFunction<SFileCompactArchiveDart>();

    // GetLastError is only available on Windows via kernel32.dll
    // On macOS/Linux, StormLib uses errno or internal error tracking
    getLastError = null;
  }
}
