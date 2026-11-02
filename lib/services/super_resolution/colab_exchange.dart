import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'super_resolution_service.dart';
import 'wav_io.dart';

/// Moves voice files to and from the Google Colab notebook
/// (colab/super_resolution.ipynb) as zip files.
///
/// Both zips hold `manifest.json` and `wav/<sha256>.wav`, where the hash is
/// that of the original 11025Hz input file, i.e. the super-resolution cache
/// key. Identical voices in several streams are sent once.
class ColabExchange {
  static const inputZipName = 'sr_input.zip';

  /// Notebook for this app version, opened in Colab straight from GitHub.
  static String notebookUrl(String appVersion) =>
      'https://colab.research.google.com/github/bubio/PSXVoice2MPQ/blob/'
      'v$appVersion/colab/super_resolution.ipynb';

  static final _entryName = RegExp(r'^wav/([0-9a-f]{64})\.wav$');

  final String cacheDir;
  final String modelId;

  ColabExchange({
    required this.cacheDir,
    this.modelId = SuperResolutionService.modelVersion,
  });

  /// Writes the 11025Hz WAV files in [wavPaths] that are not cached yet to
  /// [zipPath]. Returns the number of files written.
  Future<int> writeInput(
    List<String> wavPaths,
    String zipPath, {
    required String appVersion,
  }) async {
    final files = <String, String>{}; // sha256 -> original file name
    final encoder = ZipFileEncoder()
      ..create(zipPath, level: ZipFileEncoder.store);
    try {
      for (final path in wavPaths) {
        final bytes = await File(path).readAsBytes();
        final audio = decodePcm16Mono(bytes);
        if (audio == null || audio.sampleRate != 11025) continue;
        final hash = sha256.convert(bytes).toString();
        if (files.containsKey(hash) ||
            File(p.join(cacheDir, '$hash.wav')).existsSync()) {
          continue;
        }
        files[hash] = p.basename(path);
        encoder.addArchiveFile(ArchiveFile.bytes('wav/$hash.wav', bytes));
      }
      encoder.addArchiveFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({
            'appVersion': appVersion,
            'modelId': modelId,
            'files': [
              for (final MapEntry(key: hash, value: name) in files.entries)
                {'name': name, 'sha256': hash},
            ],
          }),
        ),
      );
    } finally {
      await encoder.close();
    }
    return files.length;
  }

  /// Copies the 44.1kHz results in the notebook's output zip into the cache.
  /// Returns the number of files imported.
  ///
  /// Throws [FormatException] if the zip is not a result for this model.
  Future<int> importResult(String zipPath) async {
    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final manifest = archive.findFile('manifest.json');
      if (manifest == null) {
        throw const FormatException('manifest.json not found');
      }
      final id = (jsonDecode(utf8.decode(manifest.content)) as Map)['modelId'];
      if (id != modelId) {
        throw FormatException('Model "$id" does not match "$modelId"');
      }

      await Directory(cacheDir).create(recursive: true);
      var imported = 0;
      for (final file in archive.files) {
        final hash = _entryName.firstMatch(file.name)?[1];
        if (!file.isFile || hash == null) continue;
        final bytes = file.content;
        final audio = decodePcm16Mono(bytes);
        if (audio == null || audio.sampleRate != 44100) continue;
        final target = p.join(cacheDir, '$hash.wav');
        final partial = File('$target.part');
        await partial.writeAsBytes(bytes, flush: true);
        await partial.rename(target);
        imported++;
      }
      return imported;
    } finally {
      await input.close();
    }
  }
}
