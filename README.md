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
</p>

## 概要

PSXVoice2MPQは、PlayStation 1版Diabloのディスクイメージから音声データを抽出し、[DevilutionX](https://github.com/diasurgical/devilutionX)で使用可能なMPQアーカイブに変換します。

<p align="center">
  <img src="assets/images/screen_shot.png" alt="PSXVoice2MPQ App ScreenShot">
</p>


### 機能

- PS1版DiabloのSTREAMファイル（STREAM1-5.DIR/BIN）から音声を抽出
- VAG音声をWAVまたはMP3形式に変換
- DevilutionX互換のMPQアーカイブを作成
- 並列処理による高速変換
- クロスプラットフォーム対応
- 25以上の言語に対応したUI

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

| OS | アーキテクチャ | ファイル名 |
|----|---------------|-----------|
| macOS | arm64 (Apple Silicon) | `PSXVoice2MPQ-macOS.dmg` |
| Windows | x86_64 (64-bit) | `PSXVoice2MPQ-Windows-x64.zip` |
| Linux | x86_64 (64-bit) | `PSXVoice2MPQ-Linux-x64.tar.gz` |

## インストール

### macOS (Homebrew)

```bash
brew tap bubio/psxvoice2mpq
brew install --cask psxvoice2mpq
```

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

## オプション依存関係

MP3出力（ファイルサイズ削減）を利用する場合は、以下のいずれかをインストールしてください：

- **lame**（推奨）: `brew install lame` / `apt install lame` / `choco install lame`
- **ffmpeg**: `brew install ffmpeg` / `apt install ffmpeg` / `choco install ffmpeg`

どちらもインストールされていない場合は、WAV形式で保存されます。

## ソースからのビルド

### 必要なもの

- [Flutter](https://flutter.dev/) 3.38.7以降
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

- [DevilutionX](https://github.com/diasurgical/devilutionX) - Diabloソースポート
- [psx-tools](https://github.com/diasurgical/psx-tools) - PS版Diabloデータ変換ツール
- [StormLib](https://github.com/ladislav-zezula/StormLib) - MPQアーカイブライブラリ
- PlayStation 1版Diablo - 開発: Climax Studios、販売: Electronic Arts

## 法的事項

このツールを使用するには、PlayStation 1版Diabloの正規コピーを所有している必要があります。本ツールには著作権で保護されたゲームアセットは含まれていません。
