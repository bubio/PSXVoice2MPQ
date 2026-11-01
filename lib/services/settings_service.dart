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
    _legacyAudioSrKeys.forEach(settings.remove);
    final file = File(_settingsFilePath);
    await Directory(p.dirname(file.path)).create(recursive: true);
    await file.writeAsString(json.encode(settings));
  }

  /// Settings keys left over from the removed AudioSR feature.
  static const _legacyAudioSrKeys = [
    'audioSrPath',
    'audioSrUseCpu',
    'audioSrChunkSeconds',
  ];

  /// Whether super-resolution (VoiceFixer) is enabled (default: false).
  Future<bool> getSuperResolutionEnabled() async {
    final settings = await _readSettings();
    return settings['sr.engine'] == 'voicefixer';
  }

  /// Saves the super-resolution setting.
  Future<void> setSuperResolutionEnabled(bool value) async {
    final settings = await _readSettings();
    settings['sr.engine'] = value ? 'voicefixer' : 'none';
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
