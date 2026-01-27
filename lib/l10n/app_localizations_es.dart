// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Carpeta de entrada';

  @override
  String get outputFolder => 'Carpeta de salida';

  @override
  String get selectInputFolder => 'Seleccionar carpeta ps1_assets';

  @override
  String get selectOutputFolder =>
      'Seleccionar carpeta de salida para archivos MPQ';

  @override
  String get buildMpq => 'Crear MPQ';

  @override
  String get building => 'Creando...';

  @override
  String get browse => 'Examinar';

  @override
  String get notSelected => 'No seleccionado';

  @override
  String get inputFolderHint =>
      'Carpeta con archivos STREAM*.DIR/BIN del disco PS1';

  @override
  String get outputFolderHint => 'Carpeta destino para archivos MPQ generados';

  @override
  String get clickBuildToStart => 'Haga clic en Crear para comenzar';

  @override
  String get starting => 'Iniciando...';

  @override
  String processing(String fileName) {
    return 'Procesando: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total archivos';
  }

  @override
  String get initializing => 'Inicializando...';

  @override
  String get extractingBinaries => 'Extrayendo binarios...';

  @override
  String get findingStreamFiles => 'Buscando archivos stream...';

  @override
  String extractingStream(String streamName) {
    return 'Extrayendo $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Convirtiendo archivos VAG de $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Creando MPQ para $streamName...';
  }

  @override
  String get cleaningUp => 'Limpiando...';

  @override
  String get complete => '¡Completado!';

  @override
  String get buildFailed => 'Error de compilación';

  @override
  String get errorSmpqNotFound => 'Comando smpq no encontrado.';

  @override
  String get errorNoStreamFiles =>
      'No se encontraron archivos STREAM*.DIR en la carpeta seleccionada.';

  @override
  String get errorOutputDirectoryNotFound => 'Output directory does not exist.';

  @override
  String convertingToMp3(String streamName) {
    return 'Convirtiendo WAV a MP3 de $streamName...';
  }
}
