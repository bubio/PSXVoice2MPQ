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
  ///
  /// `--dart-define=COLAB_NOTEBOOK_REF=<branch>` opens another revision, for
  /// trying a notebook before it is released.
  static String notebookUrl(String appVersion) {
    const ref = String.fromEnvironment('COLAB_NOTEBOOK_REF');
    return 'https://colab.research.google.com/github/bubio/PSXVoice2MPQ/blob/'
        '${ref.isEmpty ? 'v$appVersion' : ref}/colab/super_resolution.ipynb';
  }

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

  /// Reads the `sr_input.zip` at [zipPath] and counts how many of its voices
  /// are in the cache. Returns null if there is no readable zip.
  Future<ColabInputStatus?> inspectInput(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) return null;
    final input = InputFileStream(zipPath);
    try {
      final manifest = ZipDecoder()
          .decodeStream(input)
          .findFile('manifest.json');
      if (manifest == null) return null;
      final json = jsonDecode(utf8.decode(manifest.content)) as Map;
      final hashes = [
        for (final f in json['files'] as List) (f as Map)['sha256'] as String,
      ];
      return ColabInputStatus(
        path: zipPath,
        modified: await file.lastModified(),
        total: hashes.length,
        imported: hashes
            .where((h) => File(p.join(cacheDir, '$h.wav')).existsSync())
            .length,
      );
    } on Object {
      return null;
    } finally {
      await input.close();
    }
  }

  static final _outputZipName = RegExp(r'^sr_output.*\.zip$');

  /// Finds the newest `sr_output*.zip` (browsers may add " (1)") in [dirs]
  /// modified after [after]. Returns its path, or null.
  static String? findOutput(Iterable<String> dirs, {DateTime? after}) {
    File? newest;
    DateTime? newestTime;
    for (final dir in dirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final f in d.listSync().whereType<File>()) {
        if (!_outputZipName.hasMatch(p.basename(f.path))) continue;
        final time = f.lastModifiedSync();
        if (after != null && !time.isAfter(after)) continue;
        if (newestTime == null || time.isAfter(newestTime)) {
          newest = f;
          newestTime = time;
        }
      }
    }
    return newest?.path;
  }

  /// The user's Downloads folder, where the notebook's result usually lands.
  static String? downloadsDir() {
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    return home == null ? null : p.join(home, 'Downloads');
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

/// State of an exported `sr_input.zip`.
final class ColabInputStatus {
  final String path;
  final DateTime modified;

  /// Number of voices in the zip.
  final int total;

  /// Number of those voices whose result is in the cache.
  final int imported;

  const ColabInputStatus({
    required this.path,
    required this.modified,
    required this.total,
    required this.imported,
  });

  bool get complete => imported >= total;
}
