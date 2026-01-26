import 'dart:io';
import 'package:path/path.dart' as p;

/// Path-related constants
class PathConstants {
  PathConstants._();

  // Temp directory name
  static const String tempDirName = 'PSXVoice2MPQ';
  static const String binarySubdir = 'binaries';
  static const String workDirPrefix = 'psx_mpq_work_';

  // Binary names by platform
  static const List<String> windowsBinaries = ['dstream.exe'];
  static const List<String> unixBinaries = ['dstream.bin'];

  /// Get binary names for current platform
  static List<String> get binaryNames =>
      Platform.isWindows ? windowsBinaries : unixBinaries;

  /// Get platform folder name for assets
  static String get platformFolder {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    throw UnsupportedError('Unsupported platform');
  }

  /// Get dstream binary name for current platform
  static String get dstreamName =>
      Platform.isWindows ? 'dstream.exe' : 'dstream.bin';

  /// Get default output path for MPQ files (platform-specific)
  static String? getDefaultOutputPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return p.join(
          home,
          'Library',
          'Application Support',
          'diasurgical',
          'devilution',
        );
      }
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        return p.join(appData, 'diasurgical', 'devilution');
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return p.join(home, '.local', 'share', 'diasurgical', 'devilution');
      }
    }
    return null;
  }

  /// Get search paths for external executables (smpq, lame)
  static List<String> getSearchPaths(String name) {
    final paths = <String>[];
    final execName = Platform.isWindows ? '$name.exe' : name;

    if (Platform.isWindows) {
      final programFiles =
          Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
      final programFilesX86 =
          Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';

      paths.addAll([
        '$programFiles\\StormLib\\$execName',
        '$programFilesX86\\StormLib\\$execName',
        '$localAppData\\StormLib\\$execName',
        '$programFiles\\smpq\\$execName',
        '$programFilesX86\\smpq\\$execName',
      ]);
    } else if (Platform.isMacOS) {
      paths.addAll([
        '/opt/homebrew/bin/$name',
        '/usr/local/bin/$name',
        '/usr/bin/$name',
      ]);
    } else {
      // Linux
      final home = Platform.environment['HOME'] ?? '';
      paths.addAll([
        '/usr/local/bin/$name',
        '/usr/bin/$name',
        '$home/.local/bin/$name',
        '/snap/bin/$name',
      ]);
    }

    return paths;
  }
}
