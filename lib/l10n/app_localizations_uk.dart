// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Вхідна папка';

  @override
  String get outputFolder => 'Вихідна папка';

  @override
  String get selectInputFolder => 'Виберіть папку ps1_assets';

  @override
  String get selectOutputFolder => 'Виберіть папку для MPQ файлів';

  @override
  String get buildMpq => 'Створити MPQ';

  @override
  String get building => 'Створення...';

  @override
  String get browse => 'Огляд';

  @override
  String get notSelected => 'Не вибрано';

  @override
  String get inputFolderHint => 'Папка з файлами STREAM*.DIR/BIN з диска PS1';

  @override
  String get outputFolderHint => 'Папка для збереження MPQ файлів';

  @override
  String get clickBuildToStart => 'Натисніть Створити для початку';

  @override
  String get starting => 'Запуск...';

  @override
  String processing(String fileName) {
    return 'Обробка: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total файлів';
  }

  @override
  String get initializing => 'Ініціалізація...';

  @override
  String get extractingBinaries => 'Видобування бінарних файлів...';

  @override
  String get findingStreamFiles => 'Пошук stream файлів...';

  @override
  String extractingStream(String streamName) {
    return 'Видобування $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Конвертація VAG файлів з $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Створення MPQ для $streamName...';
  }

  @override
  String get cleaningUp => 'Очищення...';

  @override
  String get complete => 'Готово!';

  @override
  String get buildFailed => 'Збірка не вдалася';

  @override
  String get errorSmpqNotFound => 'Команду smpq не знайдено.';

  @override
  String get errorNoStreamFiles =>
      'Файли STREAM*.DIR не знайдено у вибраній папці.';

  @override
  String convertingToMp3(String streamName) {
    return 'Конвертація WAV в MP3 з $streamName...';
  }
}
