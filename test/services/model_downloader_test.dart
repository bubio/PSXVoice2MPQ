import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/services/super_resolution/model_downloader.dart';

/// Serves [files] over HTTP with Range support and records each request's
/// Range header.
Future<(HttpServer, List<String?>)> _serve(Map<String, Uint8List> files) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final ranges = <String?>[];
  server.listen((request) async {
    final data = files[p.basename(request.uri.path)];
    final range = request.headers.value(HttpHeaders.rangeHeader);
    ranges.add(range);
    if (data == null) {
      request.response.statusCode = HttpStatus.notFound;
    } else if (range != null) {
      final start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)![1]!);
      request.response
        ..statusCode = HttpStatus.partialContent
        ..add(data.sublist(start));
    } else {
      request.response.add(data);
    }
    await request.response.close();
  });
  return (server, ranges);
}

ModelFile _describe(String name, Uint8List data) =>
    ModelFile(name, data.length, sha256.convert(data).toString());

void main() {
  late Directory dir;
  final a = Uint8List.fromList(List.generate(5000, (i) => i % 251));
  final b = Uint8List.fromList(List.generate(300, (i) => i % 7));

  setUp(() async => dir = await Directory.systemTemp.createTemp('models_'));
  tearDown(() async => dir.delete(recursive: true));

  test('downloads every file and reports progress up to 1.0', () async {
    final (server, _) = await _serve({'a.onnx': a, 'b.onnx': b});
    addTearDown(server.close);
    final progress = <double>[];

    await ModelDownloader(
      dir.path,
      baseUrl: 'http://127.0.0.1:${server.port}',
      files: [_describe('a.onnx', a), _describe('b.onnx', b)],
    ).download(onProgress: progress.add);

    expect(File(p.join(dir.path, 'a.onnx')).readAsBytesSync(), a);
    expect(File(p.join(dir.path, 'b.onnx')).readAsBytesSync(), b);
    expect(progress.last, 1.0);
    expect(dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
  });

  test('resumes a partial download with a Range request', () async {
    final (server, ranges) = await _serve({'a.onnx': a});
    addTearDown(server.close);
    File(p.join(dir.path, 'a.onnx.part')).writeAsBytesSync(a.sublist(0, 1234));

    await ModelDownloader(
      dir.path,
      baseUrl: 'http://127.0.0.1:${server.port}',
      files: [_describe('a.onnx', a)],
    ).download();

    expect(ranges, ['bytes=1234-']);
    expect(File(p.join(dir.path, 'a.onnx')).readAsBytesSync(), a);
  });

  test('rejects a file whose SHA-256 does not match', () async {
    final (server, _) = await _serve({'a.onnx': a});
    addTearDown(server.close);

    final downloader = ModelDownloader(
      dir.path,
      baseUrl: 'http://127.0.0.1:${server.port}',
      files: [ModelFile('a.onnx', a.length, '0' * 64)],
    );

    await expectLater(downloader.download(), throwsStateError);
    expect(dir.listSync(), isEmpty);
  });

  test('skips files that are already installed', () async {
    final (server, ranges) = await _serve({});
    addTearDown(server.close);
    File(p.join(dir.path, 'a.onnx')).writeAsBytesSync(a);

    await ModelDownloader(
      dir.path,
      baseUrl: 'http://127.0.0.1:${server.port}',
      files: [_describe('a.onnx', a)],
    ).download();

    expect(ranges, isEmpty);
  });
}
