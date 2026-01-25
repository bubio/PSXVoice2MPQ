// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Входная папка';

  @override
  String get outputFolder => 'Выходная папка';

  @override
  String get selectInputFolder => 'Выберите папку ps1_assets';

  @override
  String get selectOutputFolder => 'Выберите папку для MPQ файлов';

  @override
  String get buildMpq => 'Создать MPQ';

  @override
  String get building => 'Создание...';

  @override
  String get browse => 'Обзор';

  @override
  String get notSelected => 'Не выбрано';

  @override
  String get inputFolderHint => 'Папка с файлами STREAM*.DIR/BIN с диска PS1';

  @override
  String get outputFolderHint => 'Папка для сохранения MPQ файлов';

  @override
  String get clickBuildToStart => 'Нажмите Создать для начала';

  @override
  String get starting => 'Запуск...';

  @override
  String processing(String fileName) {
    return 'Обработка: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total файлов';
  }

  @override
  String get initializing => 'Инициализация...';

  @override
  String get extractingBinaries => 'Извлечение бинарных файлов...';

  @override
  String get findingStreamFiles => 'Поиск stream файлов...';

  @override
  String extractingStream(String streamName) {
    return 'Извлечение $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Конвертация VAG файлов из $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Создание MPQ для $streamName...';
  }

  @override
  String get cleaningUp => 'Очистка...';

  @override
  String get complete => 'Готово!';

  @override
  String get errorSmpqNotFound =>
      'Команда smpq не найдена. Пожалуйста, установите инструменты StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Файлы STREAM*.DIR не найдены в выбранной папке.';

  @override
  String convertingToMp3(String streamName) {
    return 'Конвертация WAV в MP3 из $streamName...';
  }
}
