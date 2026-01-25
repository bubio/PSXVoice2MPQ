// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Belarusian (`be`).
class AppLocalizationsBe extends AppLocalizations {
  AppLocalizationsBe([String locale = 'be']) : super(locale);

  @override
  String get appTitle => 'PSX MPQ Канвертар';

  @override
  String get inputFolder => 'Уваходная папка';

  @override
  String get outputFolder => 'Выходная папка';

  @override
  String get selectInputFolder => 'Выберыце папку ps1_assets';

  @override
  String get selectOutputFolder => 'Выберыце папку для MPQ файлаў';

  @override
  String get buildMpq => 'Стварыць MPQ';

  @override
  String get building => 'Стварэнне...';

  @override
  String get browse => 'Агляд';

  @override
  String get notSelected => 'Не выбрана';

  @override
  String get clickBuildToStart => 'Націсніце Стварыць для пачатку';

  @override
  String get starting => 'Запуск...';

  @override
  String processing(String fileName) {
    return 'Апрацоўка: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total файлаў';
  }

  @override
  String get initializing => 'Ініцыялізацыя...';

  @override
  String get extractingBinaries => 'Выманне бінарных файлаў...';

  @override
  String get findingStreamFiles => 'Пошук stream файлаў...';

  @override
  String extractingStream(String streamName) {
    return 'Выманне $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return 'Канвертацыя VAG файлаў з $streamName...';
  }

  @override
  String creatingMpq(String streamName) {
    return 'Стварэнне MPQ для $streamName...';
  }

  @override
  String get cleaningUp => 'Ачыстка...';

  @override
  String get complete => 'Гатова!';

  @override
  String get errorSmpqNotFound =>
      'Каманда smpq не знойдзена. Калі ласка, усталюйце інструменты StormLib.';

  @override
  String get errorNoStreamFiles =>
      'Файлы STREAM*.DIR не знойдзены ў выбранай папцы.';
}
