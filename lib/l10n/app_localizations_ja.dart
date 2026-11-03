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

  @override
  String get superResolutionBackend => '実行場所:';

  @override
  String get backendLocal => 'このPC';

  @override
  String get superResolutionColabNote =>
      'Google Colab の無料 GPU で処理します。メイン画面の「Colab で高音質化してビルド」を押し、案内に沿って進めてください。';

  @override
  String colabImportDone(int count) {
    return '高音質化した音声を $count 件取り込みました。';
  }

  @override
  String colabImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get colabStep1Title => '音声を書き出す';

  @override
  String colabStep1Done(int count, String path) {
    return '$count 件を書き出しました: $path';
  }

  @override
  String get colabStep1Nothing => 'すべて高音質化済みです。手順 3 でビルドしてください。';

  @override
  String get colabExport => '書き出す';

  @override
  String get openFolder => 'フォルダを開く';

  @override
  String get colabStep2Title => 'Colab で変換する';

  @override
  String get openColab => 'Colab を開く';

  @override
  String get colabStep3Title => '結果を取り込んでビルド';

  @override
  String colabStep3Found(String path) {
    return '見つかりました: $path';
  }

  @override
  String colabStep3Imported(int done, int total) {
    return '取り込み済み: $done / $total 件';
  }

  @override
  String get importAndBuild => '取り込んでビルド';

  @override
  String get chooseFile => 'ファイルを選ぶ…';

  @override
  String get chooseOtherFile => '別のファイルを選ぶ';

  @override
  String get buildWithoutImport => '取り込まずにビルド（未処理の音声は元の音質のまま）';

  @override
  String get colabStart => 'Colab で高音質化してビルド…';

  @override
  String get colabWizardTitle => 'Google Colab で高音質化';

  @override
  String colabStepOf(int step) {
    return '手順 $step / 3';
  }

  @override
  String get colabStep1Explain =>
      'まだ高音質化していない音声を、出力フォルダの sr_input.zip にまとめます。次の手順で、このファイルを Colab にアップロードします。';

  @override
  String get colabExporting => '書き出し中…';

  @override
  String get colabReexport => 'もう一度書き出す';

  @override
  String get colabStep2Open => '下の「Colab を開く」を押します。';

  @override
  String get colabStep2Run => 'Colab のメニューで「ランタイム → すべてのセルを実行」を選びます。';

  @override
  String get colabStep2Upload => 'ファイルを選ぶ画面が出たら、出力フォルダの sr_input.zip を選びます。';

  @override
  String get colabStep2Wait =>
      '処理が終わると sr_output.zip がダウンロードされます。それまで Colab のタブは閉じないでください。';

  @override
  String get colabStep2Arrived => 'sr_output.zip がダウンロードされました。「次へ」を押してください。';

  @override
  String get colabStep3Explain => 'sr_output.zip から高音質化した音声を取り込み、MPQ をビルドします。';

  @override
  String get colabStep3NotFound =>
      'ダウンロードフォルダに sr_output.zip が見つかりません。ファイルを選んでください。';

  @override
  String get wizardBack => '戻る';

  @override
  String get wizardNext => '次へ';
}
