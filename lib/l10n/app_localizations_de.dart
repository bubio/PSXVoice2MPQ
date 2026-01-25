// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Eingabeordner';

  @override
  String get outputFolder => 'Ausgabeordner';

  @override
  String get selectInputFolder => 'ps1_assets-Ordner auswählen';

  @override
  String get selectOutputFolder => 'Ausgabeordner für MPQ-Dateien auswählen';

  @override
  String get buildMpq => 'MPQ erstellen';

  @override
  String get building => 'Wird erstellt...';

  @override
  String get browse => 'Durchsuchen';

  @override
  String get notSelected => 'Nicht ausgewählt';

  @override
  String get clickBuildToStart => 'Klicken Sie auf Erstellen, um zu beginnen';

  @override
  String get starting => 'Wird gestartet...';

  @override
  String processing(String fileName) {
    return 'Verarbeitung: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total Dateien';
  }

  @override
  String get initializing => 'Initialisierung...';

  @override
  String get extractingBinaries => 'Binärdateien werden extrahiert...';

  @override
  String get findingStreamFiles => 'Stream-Dateien werden gesucht...';

  @override
  String extractingStream(String streamName) {
    return '$streamName wird extrahiert...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'VAG-Dateien von $streamName werden konvertiert...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'MPQ für $streamName wird erstellt...';
  }

  @override
  String get cleaningUp => 'Aufräumen...';

  @override
  String get complete => 'Fertig!';

  @override
  String get errorSmpqNotFound =>
      'smpq-Befehl nicht gefunden. Bitte installieren Sie StormLib-Tools.';

  @override
  String get errorNoStreamFiles =>
      'Keine STREAM*.DIR-Dateien im ausgewählten Ordner gefunden.';
}
