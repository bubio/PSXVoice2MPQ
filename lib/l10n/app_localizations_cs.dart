// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'PSX MPQ Konvertor';

  @override
  String get inputFolder => 'Vstupní složka';

  @override
  String get outputFolder => 'Výstupní složka';

  @override
  String get selectInputFolder => 'Vyberte složku ps1_assets';

  @override
  String get selectOutputFolder => 'Vyberte výstupní složku pro MPQ soubory';

  @override
  String get buildMpq => 'Vytvořit MPQ';

  @override
  String get building => 'Vytváření...';

  @override
  String get browse => 'Procházet';

  @override
  String get notSelected => 'Nevybráno';

  @override
  String get clickBuildToStart => 'Klikněte na Vytvořit pro zahájení';

  @override
  String get starting => 'Spouštění...';

  @override
  String processing(String fileName) {
    return 'Zpracování: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total souborů';
  }

  @override
  String get initializing => 'Inicializace...';

  @override
  String get extractingBinaries => 'Extrakce binárních souborů...';

  @override
  String get findingStreamFiles => 'Hledání stream souborů...';

  @override
  String extractingStream(String streamName) {
    return 'Extrakce $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Konverze VAG souborů z $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Vytváření MPQ pro $streamName...';
  }

  @override
  String get cleaningUp => 'Čištění...';

  @override
  String get complete => 'Hotovo!';

  @override
  String get errorSmpqNotFound =>
      'Příkaz smpq nebyl nalezen. Nainstalujte nástroje StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Ve vybrané složce nebyly nalezeny žádné soubory STREAM*.DIR.';
}
