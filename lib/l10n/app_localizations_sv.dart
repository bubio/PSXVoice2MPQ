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
  String convertingToMp3(String streamName) {
    return 'Konverterar WAV till MP3 från $streamName...';
  }

  @override
  String enhancingAudio(String streamName) {
    return 'Förbättrar ljud med AudioSR från $streamName...';
  }

  @override
  String get enableAudioSr => 'Förbättra ljudkvalitet (AudioSR)';

  @override
  String get audioSrNotFound => 'Ange sökvägen till audiosr.';

  @override
  String get browseAudioSr => 'Bläddra...';

  @override
  String get settings => 'Inställningar';

  @override
  String get language => 'Språk';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String get cacheCleared => 'Cache rensad';

  @override
  String get audioSrNote => 'Bearbetningen kan ta mycket lång tid.';

  @override
  String get cacheFoundTitle => 'Tidigare data hittad';

  @override
  String get cacheFoundMessage =>
      'Data från en tidigare avbruten byggnation hittades. Vill du fortsätta där det slutade eller börja om?';

  @override
  String get continueFromCache => 'Fortsätt';

  @override
  String get startFresh => 'Börja om';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Öppen källkodslicenser';

  @override
  String get licensesSection => 'Licenser';

  @override
  String get audioSrUseCpu => 'Bearbeta på CPU';

  @override
  String get audioSrChunkSeconds => 'Segmentlängd (sekunder)';
}
