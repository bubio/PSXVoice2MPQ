import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../core/constants/path_constants.dart';

class BinaryExtractor {
  String? _binaryDir;

  Future<String> get binaryDirectory async {
    if (_binaryDir != null) return _binaryDir!;
    await extractBinaries();
    return _binaryDir!;
  }

  Future<void> extractBinaries() async {
    final tempDir = await getTemporaryDirectory();
    final binaryDir = Directory(
      p.join(tempDir.path, PathConstants.tempDirName, PathConstants.binarySubdir),
    );

    if (!await binaryDir.exists()) {
      await binaryDir.create(recursive: true);
    }

    _binaryDir = binaryDir.path;

    for (final binaryName in PathConstants.binaryNames) {
      final assetPath =
          'assets/binaries/${PathConstants.platformFolder}/$binaryName';
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
    return p.join(dir, PathConstants.dstreamName);
  }

  Future<String> getVag2WavPath() async {
    final dir = await binaryDirectory;
    return p.join(dir, PathConstants.vag2wavName);
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
