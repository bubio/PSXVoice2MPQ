/// Stream/language mapping constants
class StreamConstants {
  StreamConstants._();

  /// Stream number to language code mapping
  static const Map<String, String> streamToLanguage = {
    '1': 'en',
    '2': 'fr',
    '3': 'de',
    '4': 'sv',
    '5': 'ja',
  };

  /// Language display names for UI
  static const Map<String, String> languageDisplayNames = {
    'system': 'System Default',
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'sv': 'Svenska',
    'ja': '日本語',
  };

  /// Get language code from stream number
  static String getLanguageCode(String streamNum) {
    return streamToLanguage[streamNum] ?? 'stream$streamNum';
  }
}
