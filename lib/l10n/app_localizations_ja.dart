// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'PSXVoice2MPQ';

  @override
  String get inputFolder => '入力フォルダ';

  @override
  String get outputFolder => '出力フォルダ';

  @override
  String get selectInputFolder => 'ps1_assetsフォルダを選択';

  @override
  String get selectOutputFolder => 'MPQファイルの出力先を選択';

  @override
  String get buildMpq => 'MPQをビルド';

  @override
  String get building => 'ビルド中...';

  @override
  String get browse => '参照';

  @override
  String get notSelected => '未選択';

  @override
  String get inputFolderHint => 'PS1ディスクのSTREAM*.DIR/BINファイルがあるフォルダ';

  @override
  String get outputFolderHint => '生成されたMPQファイルの保存先フォルダ';

  @override
  String get clickBuildToStart => 'ビルドをクリックして開始';

  @override
  String get starting => '開始中...';

  @override
  String processing(String fileName) {
    return '処理中: $fileName';
  }

  @override
  String filesProgress(int processed, int total) {
    return '$processed / $total ファイル';
  }

  @override
  String get initializing => '初期化中...';

  @override
  String get extractingBinaries => 'バイナリを展開中...';

  @override
  String get findingStreamFiles => 'ストリームファイルを検索中...';

  @override
  String extractingStream(String streamName) {
    return '$streamNameを展開中...';
  }

  @override
  String convertingVagFiles(String streamName) {
    return '$streamNameのVAGファイルを変換中...';
  }

  @override
  String creatingMpq(String streamName) {
    return '$streamNameのMPQを作成中...';
  }

  @override
  String get cleaningUp => 'クリーンアップ中...';

  @override
  String get complete => '完了！';

  @override
  String get buildFailed => 'ビルド失敗';

  @override
  String get errorSmpqNotFound => 'smpqコマンドが見つかりません。';

  @override
  String get errorNoStreamFiles => '選択したフォルダにSTREAM*.DIRファイルが見つかりません。';

  @override
  String get errorOutputDirectoryNotFound => '出力フォルダが存在しません。';

  @override
  String get errorFilePicker => 'ファイル選択ダイアログを開けませんでした。';

  @override
  String convertingToMp3(String streamName) {
    return '$streamName の WAV を MP3 に変換中...';
  }

  @override
  String enhancingAudio(String streamName) {
    return '$streamName の音声をVoiceFixerで高音質化中...';
  }

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get clearCache => 'キャッシュを削除';

  @override
  String get cacheCleared => 'キャッシュを削除しました';

  @override
  String get version => 'バージョン';

  @override
  String get licenses => 'オープンソースライセンス';

  @override
  String get licensesSection => 'ライセンス';

  @override
  String get superResolutionSection => '音声の高音質化';

  @override
  String get enableSuperResolution => '音声を高音質化する (VoiceFixer)';

  @override
  String get superResolutionNote =>
      '11kHzの音声を44.1kHzに変換します。処理には時間がかかります（高速なPCで音声の長さの約半分、1言語あたり約1時間）。';

  @override
  String get superResolutionModelMissing => 'VoiceFixerのモデルがインストールされていません。';

  @override
  String downloadModel(String size) {
    return 'モデルをダウンロード（$size）';
  }

  @override
  String downloadingModel(int percent) {
    return 'モデルをダウンロード中... $percent%';
  }

  @override
  String modelDownloadFailed(String error) {
    return 'ダウンロードに失敗しました: $error';
  }
}
