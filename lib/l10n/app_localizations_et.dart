// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Sisendkaust';

  @override
  String get outputFolder => 'Väljundkaust';

  @override
  String get selectInputFolder => 'Valige ps1_assets kaust';

  @override
  String get selectOutputFolder => 'Valige väljundkaust MPQ failide jaoks';

  @override
  String get buildMpq => 'Loo MPQ';

  @override
  String get building => 'Loomine...';

  @override
  String get browse => 'Sirvi';

  @override
  String get notSelected => 'Pole valitud';

  @override
  String get inputFolderHint =>
      'PS1 plaadilt STREAM*.DIR/BIN faile sisaldav kaust';

  @override
  String get outputFolderHint => 'Loodud MPQ failide sihtkaust';

  @override
  String get clickBuildToStart => 'Alustamiseks klõpsake nuppu Loo';

  @override
  String get starting => 'Käivitamine...';

  @override
  String processing(String fileName) {
    return 'Töötlemine: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total faili';
  }

  @override
  String get initializing => 'Lähtestamine...';

  @override
  String get extractingBinaries => 'Binaarfailide ekstraktimine...';

  @override
  String get findingStreamFiles => 'Stream-failide otsimine...';

  @override
  String extractingStream(String streamName) {
    return '$streamName ekstraktimine...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '$streamName VAG failide teisendamine...';
  }

  @override
  String creatingMpq(String streamName) {
    return '$streamName MPQ loomine...';
  }

  @override
  String get cleaningUp => 'Puhastamine...';

  @override
  String get complete => 'Valmis!';

  @override
  String get buildFailed => 'Ehitamine ebaõnnestus';

  @override
  String get errorSmpqNotFound => 'smpq käsku ei leitud.';

  @override
  String get errorNoStreamFiles =>
      'Valitud kaustast ei leitud STREAM*.DIR faile.';

  @override
  String convertingToMp3(String streamName) {
    return 'WAV teisendamine MP3-ks failist $streamName...';
  }
}
