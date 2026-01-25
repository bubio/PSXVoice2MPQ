// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => 'Giriş Klasörü';

  @override
  String get outputFolder => 'Çıkış Klasörü';

  @override
  String get selectInputFolder => 'ps1_assets klasörünü seçin';

  @override
  String get selectOutputFolder => 'MPQ dosyaları için çıkış klasörünü seçin';

  @override
  String get buildMpq => 'MPQ Oluştur';

  @override
  String get building => 'Oluşturuluyor...';

  @override
  String get browse => 'Gözat';

  @override
  String get notSelected => 'Seçilmedi';

  @override
  String get inputFolderHint =>
      'PS1 diskinden STREAM*.DIR/BIN dosyalarını içeren klasör';

  @override
  String get outputFolderHint => 'Oluşturulan MPQ dosyaları için hedef klasör';

  @override
  String get clickBuildToStart => 'Başlamak için Oluştur\'a tıklayın';

  @override
  String get starting => 'Başlatılıyor...';

  @override
  String processing(String fileName) {
    return 'İşleniyor: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total dosya';
  }

  @override
  String get initializing => 'Başlatılıyor...';

  @override
  String get extractingBinaries => 'İkili dosyalar çıkarılıyor...';

  @override
  String get findingStreamFiles => 'Stream dosyaları aranıyor...';

  @override
  String extractingStream(String streamName) {
    return '$streamName çıkarılıyor...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '$streamName VAG dosyaları dönüştürülüyor...';
  }

  @override
  String creatingMpq(String streamName) {
    return '$streamName için MPQ oluşturuluyor...';
  }

  @override
  String get cleaningUp => 'Temizleniyor...';

  @override
  String get complete => 'Tamamlandı!';

  @override
  String get errorSmpqNotFound =>
      'smpq komutu bulunamadı. Lütfen StormLib araçlarını yükleyin.';

  @override
  String get errorNoStreamFiles =>
      'Seçilen klasörde STREAM*.DIR dosyası bulunamadı.';

  @override
  String convertingToMp3(String streamName) {
    return '$streamName WAV dosyalarını MP3\'e dönüştürülüyor...';
  }
}
