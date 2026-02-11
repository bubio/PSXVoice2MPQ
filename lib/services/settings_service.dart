import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../core/constants/path_constants.dart';

class SettingsService {
  static const String _settingsFileName = 'settings.json';

  String get _settingsFilePath =>
      p.join(PathConstants.getAppDataDir(), _settingsFileName);

  Future<Map<String, dynamic>> _readSettings() async {
    try {
      final file = File(_settingsFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore corrupt settings file
    }
    return {};
  }

  Future<void> _writeSettings(Map<String, dynamic> settings) async {
    final file = File(_settingsFilePath);
    await Directory(p.dirname(file.path)).create(recursive: true);
    await file.writeAsString(json.encode(settings));
  }

  /// Get the saved audiosr path, or null if not set.
  Future<String?> getAudioSrPath() async {
    final settings = await _readSettings();
    return settings['audioSrPath'] as String?;
  }

  /// Save the audiosr path. Pass null to clear.
  Future<void> setAudioSrPath(String? path) async {
    final settings = await _readSettings();
    if (path != null) {
      settings['audioSrPath'] = path;
    } else {
      settings.remove('audioSrPath');
    }
    await _writeSettings(settings);
  }

  /// Get the audioSrUseCpu setting (default: false).
  Future<bool> getAudioSrUseCpu() async {
    final settings = await _readSettings();
    return settings['audioSrUseCpu'] as bool? ?? false;
  }

  /// Save the audioSrUseCpu setting.
  Future<void> setAudioSrUseCpu(bool value) async {
    final settings = await _readSettings();
    settings['audioSrUseCpu'] = value;
    await _writeSettings(settings);
  }

  /// Get the audioSrChunkSeconds setting (default: 5).
  Future<int> getAudioSrChunkSeconds() async {
    final settings = await _readSettings();
    return settings['audioSrChunkSeconds'] as int? ?? 5;
  }

  /// Save the audioSrChunkSeconds setting.
  Future<void> setAudioSrChunkSeconds(int value) async {
    final settings = await _readSettings();
    settings['audioSrChunkSeconds'] = value;
    await _writeSettings(settings);
  }

  /// Get the saved locale key (e.g. 'ja', 'system'), or null if not set.
  Future<String?> getLocale() async {
    final settings = await _readSettings();
    return settings['locale'] as String?;
  }

  /// Save the locale key. Pass null to clear (use system default).
  Future<void> setLocale(String? key) async {
    final settings = await _readSettings();
    if (key != null) {
      settings['locale'] = key;
    } else {
      settings.remove('locale');
    }
    await _writeSettings(settings);
  }
}
