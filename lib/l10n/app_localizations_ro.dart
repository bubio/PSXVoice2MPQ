// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Dosar de intrare';

  @override
  String get outputFolder => 'Dosar de ieșire';

  @override
  String get selectInputFolder => 'Selectați dosarul ps1_assets';

  @override
  String get selectOutputFolder =>
      'Selectați dosarul de ieșire pentru fișierele MPQ';

  @override
  String get buildMpq => 'Creează MPQ';

  @override
  String get building => 'Se creează...';

  @override
  String get browse => 'Răsfoiește';

  @override
  String get notSelected => 'Neselectat';

  @override
  String get inputFolderHint =>
      'Folder cu fișiere STREAM*.DIR/BIN de pe discul PS1';

  @override
  String get outputFolderHint =>
      'Folder destinație pentru fișierele MPQ generate';

  @override
  String get clickBuildToStart => 'Faceți clic pe Creează pentru a începe';

  @override
  String get starting => 'Se pornește...';

  @override
  String processing(String fileName) {
    return 'Procesare: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total fișiere';
  }

  @override
  String get initializing => 'Inițializare...';

  @override
  String get extractingBinaries => 'Se extrag fișierele binare...';

  @override
  String get findingStreamFiles => 'Se caută fișierele stream...';

  @override
  String extractingStream(String streamName) {
    return 'Se extrage $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Se convertesc fișierele VAG din $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Se creează MPQ pentru $streamName...';
  }

  @override
  String get cleaningUp => 'Se curăță...';

  @override
  String get complete => 'Finalizat!';

  @override
  String get buildFailed => 'Construcție eșuată';

  @override
  String get errorSmpqNotFound => 'Comanda smpq nu a fost găsită.';

  @override
  String get errorNoStreamFiles =>
      'Nu s-au găsit fișiere STREAM*.DIR în dosarul selectat.';

  @override
  String get errorOutputDirectoryNotFound => 'Dosarul de ieșire nu există.';

  @override
  String convertingToMp3(String streamName) {
    return 'Conversie WAV în MP3 din $streamName...';
  }
}
