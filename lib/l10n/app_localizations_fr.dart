// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Convertisseur PSX MPQ';

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
  String get errorSmpqNotFound =>
      'Commande smpq introuvable. Veuillez installer les outils StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Aucun fichier STREAM*.DIR trouvé dans le dossier sélectionné.';
}
