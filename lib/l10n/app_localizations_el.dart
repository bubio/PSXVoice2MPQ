// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Φάκελος εισόδου';

  @override
  String get outputFolder => 'Φάκελος εξόδου';

  @override
  String get selectInputFolder => 'Επιλέξτε φάκελο ps1_assets';

  @override
  String get selectOutputFolder => 'Επιλέξτε φάκελο εξόδου για αρχεία MPQ';

  @override
  String get buildMpq => 'Δημιουργία MPQ';

  @override
  String get building => 'Δημιουργία...';

  @override
  String get browse => 'Αναζήτηση';

  @override
  String get notSelected => 'Δεν έχει επιλεγεί';

  @override
  String get inputFolderHint =>
      'Φάκελος με αρχεία STREAM*.DIR/BIN από δίσκο PS1';

  @override
  String get outputFolderHint =>
      'Φάκελος προορισμού για τα δημιουργημένα αρχεία MPQ';

  @override
  String get clickBuildToStart => 'Κάντε κλικ στο Δημιουργία για να ξεκινήσετε';

  @override
  String get starting => 'Εκκίνηση...';

  @override
  String processing(String fileName) {
    return 'Επεξεργασία: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total αρχεία';
  }

  @override
  String get initializing => 'Αρχικοποίηση...';

  @override
  String get extractingBinaries => 'Εξαγωγή δυαδικών αρχείων...';

  @override
  String get findingStreamFiles => 'Αναζήτηση αρχείων stream...';

  @override
  String extractingStream(String streamName) {
    return 'Εξαγωγή $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Μετατροπή αρχείων VAG από $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Δημιουργία MPQ για $streamName...';
  }

  @override
  String get cleaningUp => 'Καθαρισμός...';

  @override
  String get complete => 'Ολοκληρώθηκε!';

  @override
  String get buildFailed => 'Η κατασκευή απέτυχε';

  @override
  String get errorSmpqNotFound => 'Η εντολή smpq δεν βρέθηκε.';

  @override
  String get errorNoStreamFiles =>
      'Δεν βρέθηκαν αρχεία STREAM*.DIR στον επιλεγμένο φάκελο.';

  @override
  String get errorOutputDirectoryNotFound => 'Ο φάκελος εξόδου δεν υπάρχει.';

  @override
  String convertingToMp3(String streamName) {
    return 'Μετατροπή WAV σε MP3 από $streamName...';
  }
}
