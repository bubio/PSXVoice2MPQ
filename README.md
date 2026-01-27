# PSXVoice2MPQ

<p align="center">
  <img src="assets/icon/app_icon.png" alt="PSXVoice2MPQ" width="128" height="128">
</p>

<p align="center">
  Convert PlayStation 1 Diablo voice files to MPQ format for use with DevilutionX.
</p>

<p align="center">
  <a href="https://github.com/bubio/PSXVoice2MPQ/releases/latest">
    <img src="https://img.shields.io/github/v/release/bubio/PSXVoice2MPQ" alt="Latest Release">
  </a>
  <a href="https://github.com/bubio/PSXVoice2MPQ/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/bubio/PSXVoice2MPQ" alt="License">
  </a>
</p>

## Overview

PSXVoice2MPQ extracts voice data from PlayStation 1 Diablo disc images and converts them into MPQ archives compatible with [DevilutionX](https://github.com/diasurgical/devilutionX).

### Features

- Extracts audio from PS1 Diablo STREAM files (STREAM1-5.DIR/BIN)
- Converts VAG audio to WAV or MP3 format
- Creates MPQ archives with proper file structure for DevilutionX
- Parallel processing for fast conversion
- Cross-platform support (macOS, Windows, Linux)
- Localized UI (25+ languages)

### Supported Languages

The PS1 version of Diablo contains voice files for multiple languages:

| Stream | Language |
|--------|----------|
| STREAM1 | English |
| STREAM2 | French |
| STREAM3 | German |
| STREAM4 | Swedish |
| STREAM5 | Japanese |

## Installation

### macOS (Homebrew)

```bash
brew tap bubio/psxvoice2mpq
brew install --cask psxvoice2mpq
```

### macOS / Windows / Linux

Download the latest release from the [Releases](https://github.com/bubio/PSXVoice2MPQ/releases) page:

- **macOS**: `PSXVoice2MPQ-macOS.dmg`
- **Windows**: `PSXVoice2MPQ-Windows-x64.zip`
- **Linux**: `PSXVoice2MPQ-Linux-x64.tar.gz`

## Usage

1. **Extract PS1 disc image**: Use a tool like [dumpsxiso](https://github.com/Lameguy64/mkpsxiso) to extract your PS1 Diablo disc
2. **Launch PSXVoice2MPQ**
3. **Select input folder**: Choose the folder containing STREAM*.DIR and STREAM*.BIN files
4. **Select output folder**: Choose where to save the generated MPQ files
5. **Click "Build MPQ"**: The conversion process will start

### Output Files

The tool generates MPQ files named by language code:

- `en.mpq` - English voices
- `fr.mpq` - French voices
- `de.mpq` - German voices
- `sv.mpq` - Swedish voices
- `ja.mpq` - Japanese voices

### Using with DevilutionX

Copy the generated MPQ files to your DevilutionX data folder:

- **macOS**: `~/Library/Application Support/diasurgical/devilution/`
- **Windows**: `%APPDATA%\diasurgical\devilution\`
- **Linux**: `~/.local/share/diasurgical/devilution/`

## Optional Dependencies

For MP3 output (smaller file sizes), install one of the following:

- **lame** (recommended): `brew install lame` / `apt install lame` / `choco install lame`
- **ffmpeg**: `brew install ffmpeg` / `apt install ffmpeg` / `choco install ffmpeg`

If neither is installed, audio will be saved as WAV files.

## Building from Source

### Prerequisites

- [Flutter](https://flutter.dev/) 3.38.7 or later
- Platform-specific build tools:
  - **macOS**: Xcode
  - **Windows**: Visual Studio with C++ workload
  - **Linux**: GTK3 development libraries

### Build Commands

```bash
# Clone the repository
git clone https://github.com/bubio/PSXVoice2MPQ.git
cd PSXVoice2MPQ

# Install dependencies
flutter pub get

# Build for your platform
flutter build macos --release  # macOS
flutter build windows --release  # Windows
flutter build linux --release  # Linux
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [DevilutionX](https://github.com/diasurgical/devilutionX) - Diablo source port
- [StormLib](https://github.com/ladislav-zezula/StormLib) - MPQ archive library
- PlayStation 1 Diablo by Climax Studios

## Legal Notice

This tool requires you to own a legitimate copy of PlayStation 1 Diablo. The tool does not include any copyrighted game assets.
