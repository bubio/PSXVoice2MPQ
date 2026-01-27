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
  String get errorOutputDirectoryNotFound => 'Output directory does not exist.';

  @override
  String convertingToMp3(String streamName) {
    return 'Conversion WAV en MP3 de $streamName...';
  }
}
