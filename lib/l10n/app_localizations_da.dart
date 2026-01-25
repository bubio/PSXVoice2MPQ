// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Inputmappe';

  @override
  String get outputFolder => 'Outputmappe';

  @override
  String get selectInputFolder => 'Vælg ps1_assets-mappe';

  @override
  String get selectOutputFolder => 'Vælg outputmappe til MPQ-filer';

  @override
  String get buildMpq => 'Opret MPQ';

  @override
  String get building => 'Opretter...';

  @override
  String get browse => 'Gennemse';

  @override
  String get notSelected => 'Ikke valgt';

  @override
  String get inputFolderHint => 'Mappe med STREAM*.DIR/BIN-filer fra PS1-disc';

  @override
  String get outputFolderHint => 'Destinationsmappe til genererede MPQ-filer';

  @override
  String get clickBuildToStart => 'Klik på Opret for at starte';

  @override
  String get starting => 'Starter...';

  @override
  String processing(String fileName) {
    return 'Behandler: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total filer';
  }

  @override
  String get initializing => 'Initialiserer...';

  @override
  String get extractingBinaries => 'Udpakker binære filer...';

  @override
  String get findingStreamFiles => 'Søger efter stream-filer...';

  @override
  String extractingStream(String streamName) {
    return 'Udpakker $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Konverterer VAG-filer fra $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Opretter MPQ til $streamName...';
  }

  @override
  String get cleaningUp => 'Rydder op...';

  @override
  String get complete => 'Færdig!';

  @override
  String get buildFailed => 'Build mislykkedes';

  @override
  String get errorSmpqNotFound => 'smpq-kommandoen blev ikke fundet.';

  @override
  String get errorNoStreamFiles =>
      'Ingen STREAM*.DIR-filer fundet i den valgte mappe.';

  @override
  String convertingToMp3(String streamName) {
    return 'Konverterer WAV til MP3 fra $streamName...';
  }
}
