// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Cartella di input';

  @override
  String get outputFolder => 'Cartella di output';

  @override
  String get selectInputFolder => 'Seleziona cartella ps1_assets';

  @override
  String get selectOutputFolder => 'Seleziona cartella di output per file MPQ';

  @override
  String get buildMpq => 'Crea MPQ';

  @override
  String get building => 'Creazione in corso...';

  @override
  String get browse => 'Sfoglia';

  @override
  String get notSelected => 'Non selezionato';

  @override
  String get inputFolderHint =>
      'Cartella contenente file STREAM*.DIR/BIN dal disco PS1';

  @override
  String get outputFolderHint =>
      'Cartella di destinazione per i file MPQ generati';

  @override
  String get clickBuildToStart => 'Clicca Crea per iniziare';

  @override
  String get starting => 'Avvio...';

  @override
  String processing(String fileName) {
    return 'Elaborazione: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total file';
  }

  @override
  String get initializing => 'Inizializzazione...';

  @override
  String get extractingBinaries => 'Estrazione binari...';

  @override
  String get findingStreamFiles => 'Ricerca file stream...';

  @override
  String extractingStream(String streamName) {
    return 'Estrazione $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Conversione file VAG da $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Creazione MPQ per $streamName...';
  }

  @override
  String get cleaningUp => 'Pulizia...';

  @override
  String get complete => 'Completato!';

  @override
  String get buildFailed => 'Build fallita';

  @override
  String get errorSmpqNotFound => 'Comando smpq non trovato.';

  @override
  String get errorNoStreamFiles =>
      'Nessun file STREAM*.DIR trovato nella cartella selezionata.';

  @override
  String get errorOutputDirectoryNotFound =>
      'La cartella di output non esiste.';

  @override
  String convertingToMp3(String streamName) {
    return 'Conversione WAV in MP3 da $streamName...';
  }
}
