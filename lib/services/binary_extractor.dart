import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BinaryExtractor {
  String? _binaryDir;

  Future<String> get binaryDirectory async {
    if (_binaryDir != null) return _binaryDir!;
    await extractBinaries();
    return _binaryDir!;
  }

  String get _platformFolder {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    throw UnsupportedError('Unsupported platform');
  }

  List<String> get _binaryNames {
    if (Platform.isWindows) {
      return ['dstream.exe', 'vag2wav.exe'];
    }
    return ['dstream.bin', 'vag2wav.bin'];
  }

  Future<void> extractBinaries() async {
    final tempDir = await getTemporaryDirectory();
    final binaryDir = Directory(
      p.join(tempDir.path, 'PSXVoice2MPQ', 'binaries'),
    );

    if (!await binaryDir.exists()) {
      await binaryDir.create(recursive: true);
    }

    _binaryDir = binaryDir.path;

    for (final binaryName in _binaryNames) {
      final assetPath = 'assets/binaries/$_platformFolder/$binaryName';
      final targetPath = p.join(binaryDir.path, binaryName);
      final targetFile = File(targetPath);

      if (!await targetFile.exists()) {
        try {
          final data = await rootBundle.load(assetPath);
          await targetFile.writeAsBytes(data.buffer.asUint8List());

          if (!Platform.isWindows) {
            await Process.run('chmod', ['+x', targetPath]);
          }
        } catch (e) {
          throw Exception('Failed to extract $binaryName: $e');
        }
      }
    }
  }

  Future<String> getDstreamPath() async {
    final dir = await binaryDirectory;
    final name = Platform.isWindows ? 'dstream.exe' : 'dstream.bin';
    return p.join(dir, name);
  }

  Future<String> getVag2WavPath() async {
    final dir = await binaryDirectory;
    final name = Platform.isWindows ? 'vag2wav.exe' : 'vag2wav.bin';
    return p.join(dir, name);
  }

  Future<void> cleanup() async {
    if (_binaryDir != null) {
      final dir = Directory(_binaryDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _binaryDir = null;
    }
  }
}
