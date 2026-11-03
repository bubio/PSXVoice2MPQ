// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Indatamapp';

  @override
  String get outputFolder => 'Utdatamapp';

  @override
  String get selectInputFolder => 'Välj ps1_assets-mapp';

  @override
  String get selectOutputFolder => 'Välj utdatamapp för MPQ-filer';

  @override
  String get buildMpq => 'Skapa MPQ';

  @override
  String get building => 'Skapar...';

  @override
  String get browse => 'Bläddra';

  @override
  String get notSelected => 'Inte vald';

  @override
  String get inputFolderHint => 'Mapp med STREAM*.DIR/BIN-filer från PS1-skiva';

  @override
  String get outputFolderHint => 'Målmapp för genererade MPQ-filer';

  @override
  String get clickBuildToStart => 'Klicka på Skapa för att börja';

  @override
  String get starting => 'Startar...';

  @override
  String processing(String fileName) {
    return 'Bearbetar: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total filer';
  }

  @override
  String get initializing => 'Initierar...';

  @override
  String get extractingBinaries => 'Extraherar binärfiler...';

  @override
  String get findingStreamFiles => 'Söker stream-filer...';

  @override
  String extractingStream(String streamName) {
    return 'Extraherar $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Konverterar VAG-filer från $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Skapar MPQ för $streamName...';
  }

  @override
  String get cleaningUp => 'Städar upp...';

  @override
  String get complete => 'Klart!';

  @override
  String get buildFailed => 'Bygget misslyckades';

  @override
  String get errorSmpqNotFound => 'smpq-kommandot hittades inte.';

  @override
  String get errorNoStreamFiles =>
      'Inga STREAM*.DIR-filer hittades i den valda mappen.';

  @override
  String get errorOutputDirectoryNotFound => 'Utdatamappen finns inte.';

  @override
  String get errorFilePicker => 'Det gick inte att öppna fildialogen.';

  @override
  String convertingToMp3(String streamName) {
    return 'Konverterar WAV till MP3 från $streamName...';
  }

  @override
  String enhancingAudio(String streamName) {
    return 'Förbättrar röster i $streamName med VoiceFixer...';
  }

  @override
  String get settings => 'Inställningar';

  @override
  String get language => 'Språk';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String get cacheCleared => 'Cache rensad';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Öppen källkodslicenser';

  @override
  String get licensesSection => 'Licenser';

  @override
  String get superResolutionSection => 'Röstförbättring';

  @override
  String get enableSuperResolution => 'Förbättra röstkvaliteten (VoiceFixer)';

  @override
  String get superResolutionNote =>
      'Konverterar 11 kHz-rösterna till 44,1 kHz. Det tar en stund (ungefär hälften av ljudets längd på en snabb dator, cirka en timme per språk).';

  @override
  String get superResolutionModelMissing =>
      'VoiceFixer-modellen är inte installerad.';

  @override
  String downloadModel(String size) {
    return 'Ladda ned modellen ($size)';
  }

  @override
  String downloadingModel(int percent) {
    return 'Laddar ned modellen... $percent %';
  }

  @override
  String modelDownloadFailed(String error) {
    return 'Nedladdningen misslyckades: $error';
  }

  @override
  String get superResolutionBackend => 'Kör på:';

  @override
  String get backendLocal => 'Den här datorn';

  @override
  String get superResolutionColabNote =>
      'Körs på en gratis GPU i Google Colab. Tryck på ”Förbättra i Colab och bygg” i huvudfönstret och följ stegen.';

  @override
  String colabImportDone(int count) {
    return '$count förbättrade röster importerade.';
  }

  @override
  String colabImportFailed(String error) {
    return 'Importen misslyckades: $error';
  }

  @override
  String get colabStep1Title => 'Exportera rösterna';

  @override
  String colabStep1Done(int count, String path) {
    return '$count röster exporterade: $path';
  }

  @override
  String get colabStep1Nothing =>
      'Alla röster är redan förbättrade. Bygg i steg 3.';

  @override
  String get colabExport => 'Exportera';

  @override
  String get openFolder => 'Öppna mappen';

  @override
  String get colabStep2Title => 'Konvertera i Colab';

  @override
  String get openColab => 'Öppna Colab';

  @override
  String get colabStep3Title => 'Importera resultatet och bygg';

  @override
  String colabStep3Found(String path) {
    return 'Hittad: $path';
  }

  @override
  String colabStep3Imported(int done, int total) {
    return '$done av $total röster importerade';
  }

  @override
  String get importAndBuild => 'Importera och bygg';

  @override
  String get chooseFile => 'Välj fil…';

  @override
  String get chooseOtherFile => 'Välj en annan fil';

  @override
  String get buildWithoutImport =>
      'Bygg utan import (röster som inte förbättrats behåller originalkvaliteten)';

  @override
  String get colabStart => 'Förbättra i Colab och bygg…';

  @override
  String get colabWizardTitle => 'Förbättra med Google Colab';

  @override
  String colabStepOf(int step) {
    return 'Steg $step av 3';
  }

  @override
  String get colabStep1Explain =>
      'Samlar rösterna som ännu inte förbättrats i sr_input.zip i utdatamappen. I nästa steg laddar du upp filen till Colab.';

  @override
  String get colabExporting => 'Exporterar…';

  @override
  String get colabReexport => 'Exportera igen';

  @override
  String get colabStep2Open => 'Tryck på ”Öppna Colab” nedan.';

  @override
  String get colabStep2Run => 'Välj Körning → Kör alla i Colab.';

  @override
  String get colabStep2Upload =>
      'När en fil efterfrågas väljer du sr_input.zip i utdatamappen.';

  @override
  String get colabStep2Wait =>
      'När det är klart laddas sr_output.zip ner. Låt Colab-fliken vara öppen tills dess.';

  @override
  String get colabStep2Arrived =>
      'sr_output.zip har laddats ner. Tryck på Nästa.';

  @override
  String get colabStep3Explain =>
      'Importerar de förbättrade rösterna från sr_output.zip och bygger MPQ-filerna.';

  @override
  String get colabStep3NotFound =>
      'sr_output.zip hittades inte i mappen Hämtade filer. Välj filen själv.';

  @override
  String get wizardBack => 'Tillbaka';

  @override
  String get wizardNext => 'Nästa';
}
