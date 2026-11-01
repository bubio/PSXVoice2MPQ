import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A model file published on GitHub Releases.
final class ModelFile {
  final String name;
  final int size;
  final String sha256;

  const ModelFile(this.name, this.size, this.sha256);
}

/// Downloads the VoiceFixer model files into a directory.
///
/// Each file is downloaded to `<name>.part` (resumed with an HTTP Range
/// request if a previous attempt was interrupted), checked against its
/// SHA-256 and only then renamed, so a file under its final name is always
/// complete.
class ModelDownloader {
  /// Release that hosts the files built by tools/voicefixer_onnx/export.py.
  static const releaseUrl =
      'https://github.com/bubio/PSXVoice2MPQ/releases/download/model-data-voicefixer-1';

  static const defaultFiles = [
    ModelFile(
      'vf_front.onnx',
      38262671,
      'f805f0c1b4735fd9020c4329a5c83620c23c76f34ba0ff3e9cc2320ab5ab38d3',
    ),
    ModelFile(
      'vf_back.onnx',
      393534441,
      '30789b80cc549d4d62539d745056c7046ec1c72832edccac310d67410a60e98b',
    ),
    ModelFile(
      'vf_post.onnx',
      4468,
      'baf3a84f00751121c1ad3c2eeb7be9437ca85602763a5b0165295cc9927720e6',
    ),
  ];

  final String modelDir;
  final String baseUrl;
  final List<ModelFile> files;
  HttpClient? _client;
  bool _cancelled = false;

  ModelDownloader(
    this.modelDir, {
    this.baseUrl = releaseUrl,
    this.files = defaultFiles,
  });

  int get totalBytes => files.fold(0, (n, f) => n + f.size);

  /// Downloads the missing files. [onProgress] receives the fraction (0..1)
  /// of [totalBytes] present so far. Throws on network errors, a hash
  /// mismatch, or [cancel].
  Future<void> download({void Function(double fraction)? onProgress}) async {
    _cancelled = false;
    await Directory(modelDir).create(recursive: true);
    final client = _client = HttpClient()
      ..findProxy = HttpClient.findProxyFromEnvironment;
    try {
      var done = 0;
      void report(int fileBytes) =>
          onProgress?.call((done + fileBytes) / totalBytes);
      for (final file in files) {
        final target = File(p.join(modelDir, file.name));
        if (!await target.exists()) {
          await _downloadFile(client, file, target, report);
        }
        done += file.size;
        report(0);
      }
    } catch (_) {
      // Closing the client to cancel surfaces as a connection error.
      if (_cancelled) throw const ModelDownloadCancelled();
      rethrow;
    } finally {
      client.close(force: true);
      _client = null;
    }
  }

  Future<void> _downloadFile(
    HttpClient client,
    ModelFile file,
    File target,
    void Function(int) report,
  ) async {
    final partial = File('${target.path}.part');
    var offset = await partial.exists() ? await partial.length() : 0;
    if (offset > file.size) {
      await partial.delete();
      offset = 0;
    }

    if (offset < file.size) {
      final request = await client.getUrl(Uri.parse('$baseUrl/${file.name}'));
      if (offset > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
      }
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        offset = 0; // Server ignored the range: start over.
      } else if (response.statusCode != HttpStatus.partialContent) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: request.uri);
      }
      final sink = partial.openWrite(
        mode: offset == 0 ? FileMode.write : FileMode.append,
      );
      try {
        var received = offset;
        await for (final chunk in response) {
          if (_cancelled) throw const ModelDownloadCancelled();
          sink.add(chunk);
          received += chunk.length;
          report(received);
        }
      } finally {
        await sink.close();
      }
    }

    final digest = await sha256.bind(partial.openRead()).first;
    if (digest.toString() != file.sha256) {
      await partial.delete();
      throw StateError('SHA-256 mismatch for ${file.name}');
    }
    await partial.rename(target.path);
  }

  /// Stops [download]. The partial file is kept and resumed next time.
  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }
}

/// Thrown by [ModelDownloader.download] after [ModelDownloader.cancel].
final class ModelDownloadCancelled implements Exception {
  const ModelDownloadCancelled();
}
