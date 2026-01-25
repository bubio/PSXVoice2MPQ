// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Bemeneti mappa';

  @override
  String get outputFolder => 'Kimeneti mappa';

  @override
  String get selectInputFolder => 'Válassza ki a ps1_assets mappát';

  @override
  String get selectOutputFolder =>
      'Válassza ki a kimeneti mappát az MPQ fájlokhoz';

  @override
  String get buildMpq => 'MPQ létrehozása';

  @override
  String get building => 'Létrehozás...';

  @override
  String get browse => 'Tallózás';

  @override
  String get notSelected => 'Nincs kiválasztva';

  @override
  String get inputFolderHint =>
      'STREAM*.DIR/BIN fájlokat tartalmazó mappa a PS1 lemezről';

  @override
  String get outputFolderHint => 'Célmappa a generált MPQ fájlokhoz';

  @override
  String get clickBuildToStart => 'Kattintson a Létrehozás gombra a kezdéshez';

  @override
  String get starting => 'Indítás...';

  @override
  String processing(String fileName) {
    return 'Feldolgozás: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total fájl';
  }

  @override
  String get initializing => 'Inicializálás...';

  @override
  String get extractingBinaries => 'Bináris fájlok kicsomagolása...';

  @override
  String get findingStreamFiles => 'Stream fájlok keresése...';

  @override
  String extractingStream(String streamName) {
    return '$streamName kicsomagolása...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '$streamName VAG fájlok konvertálása...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'MPQ létrehozása $streamName számára...';
  }

  @override
  String get cleaningUp => 'Takarítás...';

  @override
  String get complete => 'Kész!';

  @override
  String get errorSmpqNotFound =>
      'Az smpq parancs nem található. Telepítse a StormLib eszközöket.';

  @override
  String get errorNoStreamFiles =>
      'Nem található STREAM*.DIR fájl a kiválasztott mappában.';

  @override
  String convertingToMp3(String streamName) {
    return 'WAV konvertálása MP3-ra: $streamName...';
  }
}
