// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Input Folder';

  @override
  String get outputFolder => 'Output Folder';

  @override
  String get selectInputFolder => 'Select ps1_assets folder';

  @override
  String get selectOutputFolder => 'Select output folder for MPQ files';

  @override
  String get buildMpq => 'Build MPQ';

  @override
  String get building => 'Building...';

  @override
  String get browse => 'Browse';

  @override
  String get notSelected => 'Not selected';

  @override
  String get inputFolderHint =>
      'Folder containing STREAM*.DIR/BIN files from PS1 disc';

  @override
  String get outputFolderHint => 'Destination folder for generated MPQ files';

  @override
  String get clickBuildToStart => 'Click Build to start';

  @override
  String get starting => 'Starting...';

  @override
  String processing(String fileName) {
    return 'Processing: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total files';
  }

  @override
  String get initializing => 'Initializing...';

  @override
  String get extractingBinaries => 'Extracting binaries...';

  @override
  String get findingStreamFiles => 'Finding stream files...';

  @override
  String extractingStream(String streamName) {
    return 'Extracting $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Converting VAG files from $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Creating MPQ for $streamName...';
  }

  @override
  String get cleaningUp => 'Cleaning up...';

  @override
  String get complete => 'Complete!';

  @override
  String get buildFailed => 'Build Failed';

  @override
  String get errorSmpqNotFound => 'smpq command not found.';

  @override
  String get errorNoStreamFiles =>
      'No STREAM*.DIR files found in the selected folder.';

  @override
  String convertingToMp3(String streamName) {
    return 'Converting WAV to MP3 from $streamName...';
  }
}
