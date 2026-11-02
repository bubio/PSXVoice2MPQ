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
  String get inputFolderHint =>
      'Ordner mit STREAM*.DIR/BIN-Dateien von PS1-Disc';

  @override
  String get outputFolderHint => 'Zielordner für generierte MPQ-Dateien';

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
  String get buildFailed => 'Build fehlgeschlagen';

  @override
  String get errorSmpqNotFound => 'smpq-Befehl nicht gefunden.';

  @override
  String get errorNoStreamFiles =>
      'Keine STREAM*.DIR-Dateien im ausgewählten Ordner gefunden.';

  @override
  String get errorOutputDirectoryNotFound =>
      'Ausgabeverzeichnis existiert nicht.';

  @override
  String get errorFilePicker => 'Der Dateidialog konnte nicht geöffnet werden.';

  @override
  String convertingToMp3(String streamName) {
    return 'Konvertiere WAV zu MP3 von $streamName...';
  }

  @override
  String enhancingAudio(String streamName) {
    return 'Stimmen in $streamName werden mit VoiceFixer verbessert...';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get clearCache => 'Cache löschen';

  @override
  String get cacheCleared => 'Cache gelöscht';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Open-Source-Lizenzen';

  @override
  String get licensesSection => 'Lizenzen';

  @override
  String get superResolutionSection => 'Sprachverbesserung';

  @override
  String get enableSuperResolution => 'Sprachqualität verbessern (VoiceFixer)';

  @override
  String get superResolutionNote =>
      'Wandelt die 11-kHz-Sprachaufnahmen in 44,1 kHz um. Das dauert eine Weile (auf einem schnellen PC etwa die Hälfte der Audiolänge, rund eine Stunde pro Sprache).';

  @override
  String get superResolutionModelMissing =>
      'Das VoiceFixer-Modell ist nicht installiert.';

  @override
  String downloadModel(String size) {
    return 'Modell herunterladen ($size)';
  }

  @override
  String downloadingModel(int percent) {
    return 'Modell wird heruntergeladen... $percent %';
  }

  @override
  String modelDownloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get superResolutionBackend => 'Ausführen auf:';

  @override
  String get backendLocal => 'Diesem PC';

  @override
  String get superResolutionColabNote =>
      'Läuft auf einer kostenlosen Google-Colab-GPU. Stimmen exportieren, im Notebook verarbeiten, Ergebnis importieren und dann erstellen.';

  @override
  String get exportForColab => 'Für Colab exportieren';

  @override
  String get openColabNotebook => 'Notebook öffnen';

  @override
  String get importColabResult => 'Colab-Ergebnis importieren';

  @override
  String colabImportDone(int count) {
    return '$count verbesserte Stimmen importiert. Beim Erstellen werden sie verwendet.';
  }

  @override
  String colabImportFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }
}
