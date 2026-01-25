// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => '输入文件夹';

  @override
  String get outputFolder => '输出文件夹';

  @override
  String get selectInputFolder => '选择 ps1_assets 文件夹';

  @override
  String get selectOutputFolder => '选择 MPQ 文件输出文件夹';

  @override
  String get buildMpq => '构建 MPQ';

  @override
  String get building => '构建中...';

  @override
  String get browse => '浏览';

  @override
  String get notSelected => '未选择';

  @override
  String get clickBuildToStart => '点击构建开始';

  @override
  String get starting => '启动中...';

  @override
  String processing(String fileName) {
    return '处理中: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total 个文件';
  }

  @override
  String get initializing => '初始化中...';

  @override
  String get extractingBinaries => '提取二进制文件...';

  @override
  String get findingStreamFiles => '查找流文件...';

  @override
  String extractingStream(String streamName) {
    return '提取 $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '转换 $streamName 的 VAG 文件...';
  }

  @override
  String creatingMpq(String streamName) {
    return '创建 $streamName 的 MPQ...';
  }

  @override
  String get cleaningUp => '清理中...';

  @override
  String get complete => '完成！';

  @override
  String get errorSmpqNotFound => '找不到 smpq 命令。请安装 StormLib 工具。';

  @override
  String get errorNoStreamFiles => '在所选文件夹中找不到 STREAM*.DIR 文件。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => '输入文件夹';

  @override
  String get outputFolder => '输出文件夹';

  @override
  String get selectInputFolder => '选择 ps1_assets 文件夹';

  @override
  String get selectOutputFolder => '选择 MPQ 文件输出文件夹';

  @override
  String get buildMpq => '构建 MPQ';

  @override
  String get building => '构建中...';

  @override
  String get browse => '浏览';

  @override
  String get notSelected => '未选择';

  @override
  String get clickBuildToStart => '点击构建开始';

  @override
  String get starting => '启动中...';

  @override
  String processing(String fileName) {
    return '处理中: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total 个文件';
  }

  @override
  String get initializing => '初始化中...';

  @override
  String get extractingBinaries => '提取二进制文件...';

  @override
  String get findingStreamFiles => '查找流文件...';

  @override
  String extractingStream(String streamName) {
    return '提取 $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '转换 $streamName 的 VAG 文件...';
  }

  @override
  String creatingMpq(String streamName) {
    return '创建 $streamName 的 MPQ...';
  }

  @override
  String get cleaningUp => '清理中...';

  @override
  String get complete => '完成！';

  @override
  String get errorSmpqNotFound => '找不到 smpq 命令。请安装 StormLib 工具。';

  @override
  String get errorNoStreamFiles => '在所选文件夹中找不到 STREAM*.DIR 文件。';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => '輸入資料夾';

  @override
  String get outputFolder => '輸出資料夾';

  @override
  String get selectInputFolder => '選擇 ps1_assets 資料夾';

  @override
  String get selectOutputFolder => '選擇 MPQ 檔案輸出資料夾';

  @override
  String get buildMpq => '建構 MPQ';

  @override
  String get building => '建構中...';

  @override
  String get browse => '瀏覽';

  @override
  String get notSelected => '未選擇';

  @override
  String get clickBuildToStart => '點擊建構開始';

  @override
  String get starting => '啟動中...';

  @override
  String processing(String fileName) {
    return '處理中: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total 個檔案';
  }

  @override
  String get initializing => '初始化中...';

  @override
  String get extractingBinaries => '提取二進位檔案...';

  @override
  String get findingStreamFiles => '尋找串流檔案...';

  @override
  String extractingStream(String streamName) {
    return '提取 $streamName...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '轉換 $streamName 的 VAG 檔案...';
  }

  @override
  String creatingMpq(String streamName) {
    return '建立 $streamName 的 MPQ...';
  }

  @override
  String get cleaningUp => '清理中...';

  @override
  String get complete => '完成！';

  @override
  String get errorSmpqNotFound => '找不到 smpq 指令。請安裝 StormLib 工具。';

  @override
  String get errorNoStreamFiles => '在所選資料夾中找不到 STREAM*.DIR 檔案。';
}
