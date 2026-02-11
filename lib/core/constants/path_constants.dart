import 'dart:io';
import 'package:path/path.dart' as p;

/// Path-related constants
class PathConstants {
  PathConstants._();

  // Temp directory name
  static const String tempDirName = 'PSXVoice2MPQ';
  static const String workDirPrefix = 'psx_mpq_work_';

  /// Get default output path for MPQ files (platform-specific)
  /// Returns null if the directory does not exist.
  static String? getDefaultOutputPath() {
    String? path;

    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        path = p.join(
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
        path = p.join(appData, 'diasurgical', 'devilution');
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        // normally installed location
        path = p.join(home, '.local', 'share', 'diasurgical', 'devilution');
        if (!Directory(path).existsSync()) {
          // flatpak installation
          path = p.join(
            home,
            '.var',
            'app',
            'org.diasurgical.DevilutionX',
            'data',
            'diasurgical',
            'devilution',
          );
        }
      }
    }

    // Return null if directory does not exist
    if (path != null && Directory(path).existsSync()) {
      return path;
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
          Platform.environment['ProgramFiles(x86)'] ??
          r'C:\Program Files (x86)';
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';

      final userProfile = Platform.environment['USERPROFILE'] ?? '';

      paths.addAll([
        '$programFiles\\StormLib\\$execName',
        '$programFilesX86\\StormLib\\$execName',
        '$localAppData\\StormLib\\$execName',
        '$programFiles\\smpq\\$execName',
        '$programFilesX86\\smpq\\$execName',
        // Python Scripts paths for pip-installed tools (e.g. audiosr)
        '$localAppData\\Programs\\Python\\Python311\\Scripts\\$execName',
        '$localAppData\\Programs\\Python\\Python312\\Scripts\\$execName',
        '$localAppData\\Programs\\Python\\Python313\\Scripts\\$execName',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\$execName',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python312\\Scripts\\$execName',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\$execName',
      ]);
    } else if (Platform.isMacOS) {
      paths.addAll([
        '/opt/homebrew/bin/$name',
        '/opt/local/bin/$name',
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

  /// Get the AudioSR cache directory for a specific stream.
  /// Cache persists across app restarts to allow resuming.
  static String getAudioSrCacheDir(String streamName) {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, 'Library', 'Caches', tempDirName, 'audiosr', streamName);
    } else if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      return p.join(localAppData, tempDirName, 'audiosr', streamName);
    } else {
      // Linux
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, '.cache', tempDirName, 'audiosr', streamName);
    }
  }

  /// Get the app cache directory.
  static String getCacheDir() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, 'Library', 'Caches', tempDirName);
    } else if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      return p.join(localAppData, tempDirName);
    } else {
      // Linux
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, '.cache', tempDirName);
    }
  }

  /// Get the app data directory for persistent settings.
  static String getAppDataDir() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, 'Library', 'Application Support', tempDirName);
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      return p.join(appData, tempDirName);
    } else {
      // Linux
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, '.config', tempDirName);
    }
  }
}
