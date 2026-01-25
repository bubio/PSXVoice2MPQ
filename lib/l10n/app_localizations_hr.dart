// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'PSX MPQ Pretvarač';

  @override
  String get inputFolder => 'Ulazna mapa';

  @override
  String get outputFolder => 'Izlazna mapa';

  @override
  String get selectInputFolder => 'Odaberite mapu ps1_assets';

  @override
  String get selectOutputFolder => 'Odaberite izlaznu mapu za MPQ datoteke';

  @override
  String get buildMpq => 'Stvori MPQ';

  @override
  String get building => 'Stvaranje...';

  @override
  String get browse => 'Pregledaj';

  @override
  String get notSelected => 'Nije odabrano';

  @override
  String get clickBuildToStart => 'Kliknite Stvori za početak';

  @override
  String get starting => 'Pokretanje...';

  @override
  String processing(String fileName) {
    return 'Obrada: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total datoteka';
  }

  @override
  String get initializing => 'Inicijalizacija...';

  @override
  String get extractingBinaries => 'Izdvajanje binarnih datoteka...';

  @override
  String get findingStreamFiles => 'Traženje stream datoteka...';

  @override
  String extractingStream(String streamName) {
    return 'Izdvajanje $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Pretvaranje VAG datoteka iz $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Stvaranje MPQ za $streamName...';
  }

  @override
  String get cleaningUp => 'Čišćenje...';

  @override
  String get complete => 'Završeno!';

  @override
  String get errorSmpqNotFound =>
      'Naredba smpq nije pronađena. Instalirajte alate StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Nisu pronađene STREAM*.DIR datoteke u odabranoj mapi.';
}
