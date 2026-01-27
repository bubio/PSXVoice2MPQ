// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Входяща папка';

  @override
  String get outputFolder => 'Изходяща папка';

  @override
  String get selectInputFolder => 'Изберете папка ps1_assets';

  @override
  String get selectOutputFolder => 'Изберете изходяща папка за MPQ файлове';

  @override
  String get buildMpq => 'Създай MPQ';

  @override
  String get building => 'Създаване...';

  @override
  String get browse => 'Преглед';

  @override
  String get notSelected => 'Не е избрано';

  @override
  String get inputFolderHint => 'Папка с файлове STREAM*.DIR/BIN от PS1 диск';

  @override
  String get outputFolderHint => 'Папка за генерираните MPQ файлове';

  @override
  String get clickBuildToStart => 'Щракнете Създай за начало';

  @override
  String get starting => 'Стартиране...';

  @override
  String processing(String fileName) {
    return 'Обработка: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total файла';
  }

  @override
  String get initializing => 'Инициализация...';

  @override
  String get extractingBinaries => 'Извличане на бинарни файлове...';

  @override
  String get findingStreamFiles => 'Търсене на stream файлове...';

  @override
  String extractingStream(String streamName) {
    return 'Извличане на $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Конвертиране на VAG файлове от $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Създаване на MPQ за $streamName...';
  }

  @override
  String get cleaningUp => 'Почистване...';

  @override
  String get complete => 'Готово!';

  @override
  String get buildFailed => 'Грешка при изграждане';

  @override
  String get errorSmpqNotFound => 'Командата smpq не е намерена.';

  @override
  String get errorNoStreamFiles =>
      'Не са намерени файлове STREAM*.DIR в избраната папка.';

  @override
  String get errorOutputDirectoryNotFound => 'Output directory does not exist.';

  @override
  String convertingToMp3(String streamName) {
    return 'Конвертиране на WAV в MP3 от $streamName...';
  }
}
