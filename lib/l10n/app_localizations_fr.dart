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
  String get errorFilePicker =>
      'Impossible d\'ouvrir la boîte de dialogue de fichiers.';

  @override
  String convertingToMp3(String streamName) {
    return 'Conversion WAV en MP3 de $streamName...';
  }

  @override
  String enhancingAudio(String streamName) {
    return 'Amélioration des voix de $streamName avec VoiceFixer...';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get cacheCleared => 'Cache vidé';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licences open source';

  @override
  String get licensesSection => 'Licences';

  @override
  String get superResolutionSection => 'Amélioration de la voix';

  @override
  String get enableSuperResolution =>
      'Améliorer la qualité des voix (VoiceFixer)';

  @override
  String get superResolutionNote =>
      'Convertit les voix de 11 kHz en 44,1 kHz. Le traitement prend du temps (environ la moitié de la durée audio sur un PC rapide, soit environ une heure par langue).';

  @override
  String get superResolutionModelMissing =>
      'Le modèle VoiceFixer n\'est pas installé.';

  @override
  String downloadModel(String size) {
    return 'Télécharger le modèle ($size)';
  }

  @override
  String downloadingModel(int percent) {
    return 'Téléchargement du modèle... $percent %';
  }

  @override
  String modelDownloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get superResolutionBackend => 'Exécuter sur :';

  @override
  String get backendLocal => 'Ce PC';

  @override
  String get superResolutionColabNote =>
      'Utilise un GPU Google Colab gratuit. Cliquez sur « Améliorer avec Colab et créer » dans la fenêtre principale et suivez les étapes.';

  @override
  String colabImportDone(int count) {
    return '$count voix améliorées importées.';
  }

  @override
  String colabImportFailed(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get colabStep1Title => 'Exporter les voix';

  @override
  String colabStep1Done(int count, String path) {
    return '$count voix exportées : $path';
  }

  @override
  String get colabStep1Nothing =>
      'Toutes les voix sont déjà améliorées. Créez à l\'étape 3.';

  @override
  String get colabExport => 'Exporter';

  @override
  String get openFolder => 'Ouvrir le dossier';

  @override
  String get colabStep2Title => 'Convertir dans Colab';

  @override
  String get openColab => 'Ouvrir Colab';

  @override
  String get colabStep3Title => 'Importer le résultat et créer';

  @override
  String colabStep3Found(String path) {
    return 'Trouvé : $path';
  }

  @override
  String colabStep3Imported(int done, int total) {
    return '$done voix importées sur $total';
  }

  @override
  String get importAndBuild => 'Importer et créer';

  @override
  String get chooseFile => 'Choisir un fichier…';

  @override
  String get chooseOtherFile => 'Choisir un autre fichier';

  @override
  String get buildWithoutImport =>
      'Créer sans importer (les voix non améliorées gardent la qualité d\'origine)';

  @override
  String get colabStart => 'Améliorer avec Colab et créer…';

  @override
  String get colabWizardTitle => 'Améliorer avec Google Colab';

  @override
  String colabStepOf(int step) {
    return 'Étape $step sur 3';
  }

  @override
  String get colabStep1Explain =>
      'Rassemble les voix à améliorer dans sr_input.zip, dans le dossier de sortie. À l\'étape suivante, vous enverrez ce fichier à Colab.';

  @override
  String get colabExporting => 'Exportation…';

  @override
  String get colabReexport => 'Exporter à nouveau';

  @override
  String get colabStep2Open => 'Cliquez sur « Ouvrir Colab » ci-dessous.';

  @override
  String get colabStep2Run =>
      'Dans Colab, choisissez Exécution → Tout exécuter.';

  @override
  String get colabStep2Upload =>
      'Quand un fichier est demandé, choisissez sr_input.zip dans le dossier de sortie.';

  @override
  String get colabStep2Wait =>
      'À la fin, sr_output.zip est téléchargé. Gardez l\'onglet Colab ouvert jusque-là.';

  @override
  String get colabStep2Arrived =>
      'sr_output.zip a été téléchargé. Cliquez sur Suivant.';

  @override
  String get colabStep3Explain =>
      'Importe les voix améliorées de sr_output.zip et crée les fichiers MPQ.';

  @override
  String get colabStep3NotFound =>
      'sr_output.zip est introuvable dans le dossier Téléchargements. Choisissez-le vous-même.';

  @override
  String get wizardBack => 'Retour';

  @override
  String get wizardNext => 'Suivant';
}
