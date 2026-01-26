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
    'ja': '日本語',
    'ko': '한국어',
    'zh_CN': '简体中文',
    'zh_TW': '繁體中文',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'pt_BR': 'Português (Brasil)',
    'ru': 'Русский',
    'uk': 'Українська',
    'pl': 'Polski',
    'cs': 'Čeština',
    'hu': 'Magyar',
    'ro': 'Română',
    'bg': 'Български',
    'hr': 'Hrvatski',
    'sv': 'Svenska',
    'da': 'Dansk',
    'fi': 'Suomi',
    'et': 'Eesti',
    'el': 'Ελληνικά',
    'tr': 'Türkçe',
    'be': 'Беларуская',
  };

  /// Get language code from stream number
  static String getLanguageCode(String streamNum) {
    return streamToLanguage[streamNum] ?? 'stream$streamNum';
  }
}
