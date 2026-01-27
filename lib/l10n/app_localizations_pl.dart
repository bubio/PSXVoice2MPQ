// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Folder wejściowy';

  @override
  String get outputFolder => 'Folder wyjściowy';

  @override
  String get selectInputFolder => 'Wybierz folder ps1_assets';

  @override
  String get selectOutputFolder => 'Wybierz folder wyjściowy dla plików MPQ';

  @override
  String get buildMpq => 'Utwórz MPQ';

  @override
  String get building => 'Tworzenie...';

  @override
  String get browse => 'Przeglądaj';

  @override
  String get notSelected => 'Nie wybrano';

  @override
  String get inputFolderHint => 'Folder z plikami STREAM*.DIR/BIN z płyty PS1';

  @override
  String get outputFolderHint =>
      'Folder docelowy dla wygenerowanych plików MPQ';

  @override
  String get clickBuildToStart => 'Kliknij Utwórz, aby rozpocząć';

  @override
  String get starting => 'Uruchamianie...';

  @override
  String processing(String fileName) {
    return 'Przetwarzanie: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total plików';
  }

  @override
  String get initializing => 'Inicjalizacja...';

  @override
  String get extractingBinaries => 'Wypakowywanie plików binarnych...';

  @override
  String get findingStreamFiles => 'Wyszukiwanie plików stream...';

  @override
  String extractingStream(String streamName) {
    return 'Wypakowywanie $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Konwertowanie plików VAG z $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Tworzenie MPQ dla $streamName...';
  }

  @override
  String get cleaningUp => 'Czyszczenie...';

  @override
  String get complete => 'Ukończono!';

  @override
  String get buildFailed => 'Budowanie nie powiodło się';

  @override
  String get errorSmpqNotFound => 'Nie znaleziono polecenia smpq.';

  @override
  String get errorNoStreamFiles =>
      'Nie znaleziono plików STREAM*.DIR w wybranym folderze.';

  @override
  String get errorOutputDirectoryNotFound => 'Output directory does not exist.';

  @override
  String convertingToMp3(String streamName) {
    return 'Konwersja WAV do MP3 z $streamName...';
  }
}
