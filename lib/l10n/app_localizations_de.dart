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
  String convertingToMp3(String streamName) {
    return 'Konvertiere WAV zu MP3 von $streamName...';
  }

  @override
  String enhancingAudio(String streamName) {
    return 'Audio mit AudioSR von $streamName wird verbessert...';
  }

  @override
  String get enableAudioSr => 'Audioqualität verbessern (AudioSR)';

  @override
  String get audioSrNotFound => 'Bitte geben Sie die audiosr-Programmdatei an.';

  @override
  String get browseAudioSr => 'Durchsuchen...';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get clearCache => 'Cache löschen';

  @override
  String get cacheCleared => 'Cache gelöscht';

  @override
  String get audioSrNote => 'Die Verarbeitung kann sehr lange dauern.';

  @override
  String get cacheFoundTitle => 'Vorherige Daten gefunden';

  @override
  String get cacheFoundMessage =>
      'Es wurden Daten eines zuvor abgebrochenen Builds gefunden. Möchten Sie fortfahren oder neu beginnen?';

  @override
  String get continueFromCache => 'Fortfahren';

  @override
  String get startFresh => 'Neu beginnen';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Open-Source-Lizenzen';

  @override
  String get licensesSection => 'Lizenzen';

  @override
  String get audioSrUseCpu => 'Auf CPU verarbeiten';

  @override
  String get audioSrChunkSeconds => 'Chunk-Dauer (Sekunden)';
}
