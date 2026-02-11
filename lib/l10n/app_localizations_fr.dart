// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Dossier d\'entrée';

  @override
  String get outputFolder => 'Dossier de sortie';

  @override
  String get selectInputFolder => 'Sélectionner le dossier ps1_assets';

  @override
  String get selectOutputFolder =>
      'Sélectionner le dossier de sortie pour les fichiers MPQ';

  @override
  String get buildMpq => 'Créer MPQ';

  @override
  String get building => 'Création en cours...';

  @override
  String get browse => 'Parcourir';

  @override
  String get notSelected => 'Non sélectionné';

  @override
  String get inputFolderHint =>
      'Dossier contenant les fichiers STREAM*.DIR/BIN du disque PS1';

  @override
  String get outputFolderHint =>
      'Dossier de destination pour les fichiers MPQ générés';

  @override
  String get clickBuildToStart => 'Cliquez sur Créer pour commencer';

  @override
  String get starting => 'Démarrage...';

  @override
  String processing(String fileName) {
    return 'Traitement : $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total fichiers';
  }

  @override
  String get initializing => 'Initialisation...';

  @override
  String get extractingBinaries => 'Extraction des binaires...';

  @override
  String get findingStreamFiles => 'Recherche des fichiers stream...';

  @override
  String extractingStream(String streamName) {
    return 'Extraction de $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Conversion des fichiers VAG de $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Création du MPQ pour $streamName...';
  }

  @override
  String get cleaningUp => 'Nettoyage...';

  @override
  String get complete => 'Terminé !';

  @override
  String get buildFailed => 'Échec de la construction';

  @override
  String get errorSmpqNotFound => 'Commande smpq introuvable.';

  @override
  String get errorNoStreamFiles =>
      'Aucun fichier STREAM*.DIR trouvé dans le dossier sélectionné.';

  @override
  String get errorOutputDirectoryNotFound =>
      'Le dossier de sortie n\'existe pas.';

  @override
  String convertingToMp3(String streamName) {
    return 'Conversion WAV en MP3 de $streamName...';
  }

  @override
  String enhancingAudio(String streamName) {
    return 'Amélioration audio avec AudioSR de $streamName...';
  }

  @override
  String get enableAudioSr => 'Améliorer la qualité audio (AudioSR)';

  @override
  String get audioSrNotFound => 'Veuillez spécifier l\'exécutable audiosr.';

  @override
  String get browseAudioSr => 'Parcourir...';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get cacheCleared => 'Cache vidé';

  @override
  String get audioSrNote => 'Le traitement peut prendre très longtemps.';

  @override
  String get cacheFoundTitle => 'Données précédentes trouvées';

  @override
  String get cacheFoundMessage =>
      'Des données d\'une construction précédemment interrompue ont été trouvées. Voulez-vous reprendre ou recommencer ?';

  @override
  String get continueFromCache => 'Reprendre';

  @override
  String get startFresh => 'Recommencer';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licences open source';

  @override
  String get licensesSection => 'Licences';

  @override
  String get audioSrUseCpu => 'Traitement sur CPU';

  @override
  String get audioSrChunkSeconds => 'Durée des segments (secondes)';
}
