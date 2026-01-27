// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Syötekansio';

  @override
  String get outputFolder => 'Tulostekansio';

  @override
  String get selectInputFolder => 'Valitse ps1_assets-kansio';

  @override
  String get selectOutputFolder => 'Valitse tulostekansio MPQ-tiedostoille';

  @override
  String get buildMpq => 'Luo MPQ';

  @override
  String get building => 'Luodaan...';

  @override
  String get browse => 'Selaa';

  @override
  String get notSelected => 'Ei valittu';

  @override
  String get inputFolderHint =>
      'Kansio, joka sisältää STREAM*.DIR/BIN-tiedostot PS1-levyltä';

  @override
  String get outputFolderHint => 'Kohdekansio luoduille MPQ-tiedostoille';

  @override
  String get clickBuildToStart => 'Aloita napsauttamalla Luo';

  @override
  String get starting => 'Käynnistetään...';

  @override
  String processing(String fileName) {
    return 'Käsitellään: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total tiedostoa';
  }

  @override
  String get initializing => 'Alustetaan...';

  @override
  String get extractingBinaries => 'Puretaan binääritiedostoja...';

  @override
  String get findingStreamFiles => 'Etsitään stream-tiedostoja...';

  @override
  String extractingStream(String streamName) {
    return 'Puretaan $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Muunnetaan $streamName VAG-tiedostoja...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Luodaan MPQ $streamName...';
  }

  @override
  String get cleaningUp => 'Siivotaan...';

  @override
  String get complete => 'Valmis!';

  @override
  String get buildFailed => 'Rakennus epäonnistui';

  @override
  String get errorSmpqNotFound => 'smpq-komentoa ei löydy.';

  @override
  String get errorNoStreamFiles =>
      'STREAM*.DIR-tiedostoja ei löytynyt valitusta kansiosta.';

  @override
  String get errorOutputDirectoryNotFound => 'Tulostekansiota ei ole olemassa.';

  @override
  String convertingToMp3(String streamName) {
    return 'Muunnetaan WAV MP3:ksi kohteesta $streamName...';
  }
}
