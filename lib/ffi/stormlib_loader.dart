import 'dart:ffi';
import 'dart:io';

import 'stormlib_bindings.dart';

/// Platform-specific StormLib library loader.
class StormLibLoader {
  StormLibLoader._();

  static DynamicLibrary? _cachedLibrary;
  static StormLibBindings? _cachedBindings;

  /// Get the library name for the current platform.
  static String get libraryName {
    if (Platform.isMacOS) {
      return 'libStorm.dylib';
    } else if (Platform.isWindows) {
      return 'StormLib.dll';
    } else if (Platform.isLinux) {
      return 'libStorm.so';
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Get the expected library path for the current platform.
  static String? get libraryPath {
    final executableDir = File(Platform.resolvedExecutable).parent;

    if (Platform.isMacOS) {
      // On macOS, libraries are in the Frameworks directory inside the app bundle
      // App structure: App.app/Contents/MacOS/executable
      // Libraries at: App.app/Contents/Frameworks/libStorm.dylib
      final frameworksDir = Directory(
        '${executableDir.path}/../Frameworks',
      );
      final libPath = '${frameworksDir.path}/$libraryName';
      if (File(libPath).existsSync()) {
        return libPath;
      }
      // Also check in the same directory as executable (for development)
      final devPath = '${executableDir.path}/$libraryName';
      if (File(devPath).existsSync()) {
        return devPath;
      }
    } else if (Platform.isWindows) {
      // On Windows, DLLs are in the same directory as the executable
      final libPath = '${executableDir.path}/$libraryName';
      if (File(libPath).existsSync()) {
        return libPath;
      }
    } else if (Platform.isLinux) {
      // On Linux, .so files are in the lib directory
      final libDir = Directory('${executableDir.path}/lib');
      final libPath = '${libDir.path}/$libraryName';
      if (File(libPath).existsSync()) {
        return libPath;
      }
      // Also check in the same directory as executable (for development)
      final devPath = '${executableDir.path}/$libraryName';
      if (File(devPath).existsSync()) {
        return devPath;
      }
    }

    return null;
  }

  /// Check if the StormLib library is available on this platform.
  static bool get isAvailable {
    return libraryPath != null;
  }

  /// Load the StormLib dynamic library.
  /// Returns null if the library cannot be loaded.
  static DynamicLibrary? loadLibrary() {
    if (_cachedLibrary != null) {
      return _cachedLibrary;
    }

    final path = libraryPath;
    if (path == null) {
      return null;
    }

    try {
      _cachedLibrary = DynamicLibrary.open(path);
      return _cachedLibrary;
    } catch (e) {
      // Failed to load library
      return null;
    }
  }

  /// Get StormLib FFI bindings.
  /// Returns null if the library cannot be loaded.
  static StormLibBindings? getBindings() {
    if (_cachedBindings != null) {
      return _cachedBindings;
    }

    final lib = loadLibrary();
    if (lib == null) {
      return null;
    }

    try {
      _cachedBindings = StormLibBindings(lib);
      return _cachedBindings;
    } catch (e) {
      // Failed to create bindings (missing symbols, etc.)
      return null;
    }
  }
}
