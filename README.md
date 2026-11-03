# PSXVoice2MPQ

<p align="center">
  <img src="assets/icon/app_icon.png" alt="PSXVoice2MPQ" width="128" height="128">
</p>

<p align="center">
  PlayStation 1版Diabloの音声ファイルをDevilutionX用のMPQ形式に変換するツール
</p>

<p align="center">
  <a href="https://github.com/bubio/PSXVoice2MPQ/releases/latest">
    <img src="https://img.shields.io/github/v/release/bubio/PSXVoice2MPQ" alt="Latest Release">
  </a>
  <a href="https://github.com/bubio/PSXVoice2MPQ/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/bubio/PSXVoice2MPQ" alt="License">
  </a>
  <a href="https://github.com/bubio/PSXVoice2MPQ/releases/latest">
    <img src="https://img.shields.io/github/downloads/bubio/PSXVoice2MPQ/total.svg" alt="Downloads">
  </a>
</p>

## 概要

PSXVoice2MPQは、PlayStation 1版Diabloのゲームディスクから音声データを抽出し、[DevilutionX](https://github.com/diasurgical/devilutionX)で使用可能なMPQアーカイブに変換します。

<p align="center">
  <img src="assets/images/screen_shot.png" alt="PSXVoice2MPQ App ScreenShot">
</p>


### 機能

- PS1版DiabloのSTREAMファイル（STREAM1-5.DIR/BIN）から音声を抽出
- VAG音声をWAVに変換（音楽は変換対象外）
- LAME、またはFFMPEGが使用可能な場合はMP3に変換
- DevilutionX互換のMPQアーカイブを作成
- **VoiceFixerによる音声の高音質化（オプション）**: 11kHzの音声を44.1kHzに変換

### 対応言語（音声）

PS1版Diabloには以下の言語の音声ファイルが含まれています：

| Stream | 言語 | 地域 |
|--------|------|------|
| STREAM1 | 英語 | Europe/USA |
| STREAM2 | フランス語 | Europe/USA |
| STREAM3 | ドイツ語 | Europe/USA |
| STREAM4 | スウェーデン語 | Europe/USA |
| STREAM5 | 日本語 | 日本 |

## 対応プラットフォーム

| OS | アーキテクチャ |
|----|---------------|
| macOS | Intel / Appleシリコン |
| Windows | x86_64 / ARM64 |
| Linux | x86_64 / ARM64 |

## インストール

### macOS (Homebrew)

```bash
brew tap bubio/psxvoice2mpq
brew install --cask psxvoice2mpq
```

> **注意**: このアプリはAppleによるノータリゼーション（公証）を受けていないため、初回起動時にGatekeeperによってブロックされる場合があります。以下のいずれかの方法で回避できます：
>
> **方法1: ターミナルで隔離フラグを削除**
> ```bash
> xattr -cr /Applications/PSXVoice2MPQ.app
> ```
>
> **方法2: システム設定から許可**
> 1. アプリを開こうとしてブロックされた後
> 2. 「システム設定」→「プライバシーとセキュリティ」を開く
> 3. 「"PSXVoice2MPQ"は開発元を確認できないため、使用がブロックされました」の横にある「このまま開く」をクリック

### 直接ダウンロード

[Releases](https://github.com/bubio/PSXVoice2MPQ/releases)ページから最新版をダウンロードしてください。

## 使い方

1. **PSXVoice2MPQを起動**
2. **入力フォルダを選択**: STREAM*.DIRとSTREAM*.BINファイルが含まれるフォルダを選択
3. **出力フォルダを選択**: MPQファイルの保存先を選択
4. **「MPQをビルド」をクリック**: 変換処理が開始されます

### 出力ファイル

言語コード別にMPQファイルが生成されます：

- `en.mpq` - 英語音声
- `fr.mpq` - フランス語音声
- `de.mpq` - ドイツ語音声
- `sv.mpq` - スウェーデン語音声
- `ja.mpq` - 日本語音声

### DevilutionXでの使用

生成されたMPQファイルをDevilutionXのデータフォルダにコピーしてください：

- **macOS**: `~/Library/Application Support/diasurgical/devilution/`
- **Windows**: `%APPDATA%\diasurgical\devilution\`
- **Linux**: `~/.local/share/diasurgical/devilution/`、またはFlatpackでインストールした場合は、`~/.var/app/org.diasurgical.DevilutionX/data/diasurgical/devilution/`

DevilutionXを起動したことがあれば、出力先として自動的に設定されます。

## 音声の高音質化（VoiceFixer）

PS1版Diabloの音声は11kHzで収録されています。設定画面で「音声を高音質化する」をオンにすると、AIによる音声超解像（[VoiceFixer](https://github.com/haoheliu/voicefixer)）で44.1kHzに変換してからMPQを作ります。Pythonなどの準備は不要です。

実行場所は次の2つから選べます。

- **このPC**: 初回にモデル（約430MB）をダウンロードし、アプリ内で処理します。音声の長さの約半分の時間がかかります（Apple M4で1言語あたり約1時間）。
- **Google Colab**: 無料のGPUで処理します。Colabはブラウザで操作する必要があるため、メイン画面の「Colab で高音質化してビルド」を押すと、3つの手順を1つずつ案内します。
  1. 「書き出す」を押すと、出力フォルダに `sr_input.zip` ができます。
  2. 「Colab を開く」でColabを開き、すべてのセルを実行して `sr_input.zip` を選びます。終わると `sr_output.zip` がダウンロードされます。
  3. アプリに戻ると、ダウンロードフォルダの `sr_output.zip` を自動で見つけます。「取り込んでビルド」を押します。

処理結果はキャッシュされます。ビルドを中断しても、もう一度ビルドすれば続きから処理します。キャッシュは設定画面の「キャッシュを削除」で消せます。

## ソースからのビルド

### 必要なもの

- [Flutter](https://flutter.dev/) 3.38.7
- プラットフォーム別のビルドツール：
  - **macOS**: Xcode
  - **Windows**: Visual Studio（C++ワークロード）
  - **Linux**: GTK3開発ライブラリ

### ビルドコマンド

```bash
# リポジトリをクローン
git clone https://github.com/bubio/PSXVoice2MPQ.git
cd PSXVoice2MPQ

# 依存関係をインストール
flutter pub get

# ビルド
flutter build macos --release  # macOS
flutter build windows --release  # Windows
flutter build linux --release  # Linux
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 謝辞

- [DevilutionX](https://github.com/diasurgical/devilutionX) - DevilutionXは『ディアブロ』と『ヘルファイア』を多様なプラットフォームで動作
- [psx-tools](https://github.com/diasurgical/psx-tools) - PS版Diabloデータ変換ツール
- [StormLib](https://github.com/ladislav-zezula/StormLib) - MPQアーカイブライブラリ
- [VoiceFixer](https://github.com/haoheliu/voicefixer) - AI音声超解像（モデルの重みは CC BY 4.0）
- [ONNX Runtime](https://github.com/microsoft/onnxruntime) - 推論エンジン
- PlayStation 1版Diablo - 開発: Climax Studios、販売: Electronic Arts

## 法的事項

このツールを使用するには、PlayStation 1版Diabloの正規コピーを所有している必要があります。本ツールには著作権で保護されたゲームアセットは含まれていません。
