// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Pasta de entrada';

  @override
  String get outputFolder => 'Pasta de saída';

  @override
  String get selectInputFolder => 'Selecione a pasta ps1_assets';

  @override
  String get selectOutputFolder =>
      'Selecione a pasta de saída para arquivos MPQ';

  @override
  String get buildMpq => 'Criar MPQ';

  @override
  String get building => 'Criando...';

  @override
  String get browse => 'Procurar';

  @override
  String get notSelected => 'Não selecionado';

  @override
  String get clickBuildToStart => 'Clique em Criar para começar';

  @override
  String get starting => 'Iniciando...';

  @override
  String processing(String fileName) {
    return 'Processando: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total arquivos';
  }

  @override
  String get initializing => 'Inicializando...';

  @override
  String get extractingBinaries => 'Extraindo binários...';

  @override
  String get findingStreamFiles => 'Procurando arquivos stream...';

  @override
  String extractingStream(String streamName) {
    return 'Extraindo $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Convertendo arquivos VAG de $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Criando MPQ para $streamName...';
  }

  @override
  String get cleaningUp => 'Limpando...';

  @override
  String get complete => 'Concluído!';

  @override
  String get errorSmpqNotFound =>
      'Comando smpq não encontrado. Instale as ferramentas StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Nenhum arquivo STREAM*.DIR encontrado na pasta selecionada.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Pasta de entrada';

  @override
  String get outputFolder => 'Pasta de saída';

  @override
  String get selectInputFolder => 'Selecione a pasta ps1_assets';

  @override
  String get selectOutputFolder =>
      'Selecione a pasta de saída para arquivos MPQ';

  @override
  String get buildMpq => 'Criar MPQ';

  @override
  String get building => 'Criando...';

  @override
  String get browse => 'Procurar';

  @override
  String get notSelected => 'Não selecionado';

  @override
  String get clickBuildToStart => 'Clique em Criar para começar';

  @override
  String get starting => 'Iniciando...';

  @override
  String processing(String fileName) {
    return 'Processando: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total arquivos';
  }

  @override
  String get initializing => 'Inicializando...';

  @override
  String get extractingBinaries => 'Extraindo binários...';

  @override
  String get findingStreamFiles => 'Procurando arquivos stream...';

  @override
  String extractingStream(String streamName) {
    return 'Extraindo $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Convertendo arquivos VAG de $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Criando MPQ para $streamName...';
  }

  @override
  String get cleaningUp => 'Limpando...';

  @override
  String get complete => 'Concluído!';

  @override
  String get errorSmpqNotFound =>
      'Comando smpq não encontrado. Instale as ferramentas StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Nenhum arquivo STREAM*.DIR encontrado na pasta selecionada.';
}
