// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'PSX MPQ 변환기';

  @override
  String get inputFolder => '입력 폴더';

  @override
  String get outputFolder => '출력 폴더';

  @override
  String get selectInputFolder => 'ps1_assets 폴더 선택';

  @override
  String get selectOutputFolder => 'MPQ 파일 출력 폴더 선택';

  @override
  String get buildMpq => 'MPQ 빌드';

  @override
  String get building => '빌드 중...';

  @override
  String get browse => '찾아보기';

  @override
  String get notSelected => '선택되지 않음';

  @override
  String get clickBuildToStart => '빌드를 클릭하여 시작';

  @override
  String get starting => '시작 중...';

  @override
  String processing(String fileName) {
    return '처리 중: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total 파일';
  }

  @override
  String get initializing => '초기화 중...';

  @override
  String get extractingBinaries => '바이너리 추출 중...';

  @override
  String get findingStreamFiles => '스트림 파일 검색 중...';

  @override
  String extractingStream(String streamName) {
    return '$streamName 추출 중...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '$streamName의 VAG 파일 변환 중...';
  }

  @override
  String creatingMpq(String streamName) {
    return '$streamName의 MPQ 생성 중...';
  }

  @override
  String get cleaningUp => '정리 중...';

  @override
  String get complete => '완료!';

  @override
  String get errorSmpqNotFound => 'smpq 명령을 찾을 수 없습니다. StormLib 도구를 설치하세요.';

  @override
  String get errorNoStreamFiles => '선택한 폴더에서 STREAM*.DIR 파일을 찾을 수 없습니다.';
}
