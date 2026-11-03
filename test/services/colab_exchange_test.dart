import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/services/super_resolution/colab_exchange.dart';
import 'package:psxvoice2mpq/services/super_resolution/wav_io.dart';

Uint8List _wav(double value, int rate) =>
    encodePcm16Mono(Float32List.fromList([value, -value]), rate);

void main() {
  late Directory dir;
  late ColabExchange exchange;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('colab_');
    exchange = ColabExchange(
      cacheDir: p.join(dir.path, 'cache'),
      modelId: 'test-model',
    );
  });
  tearDown(() => dir.delete(recursive: true));

  String write(String name, Uint8List bytes) {
    final path = p.join(dir.path, name);
    File(path).writeAsBytesSync(bytes);
    return path;
  }

  Archive readZip(String path) =>
      ZipDecoder().decodeBytes(File(path).readAsBytesSync());

  test('export sends each uncached voice once, keyed by its hash', () async {
    final a = _wav(0.1, 11025);
    final cached = _wav(0.2, 11025);
    File(p.join(exchange.cacheDir, '${sha256.convert(cached)}.wav'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(_wav(0.2, 44100));
    final paths = [
      write('A1.WAV', a),
      write('A2.WAV', a), // same audio in another stream
      write('C.WAV', cached),
      write('HI.WAV', _wav(0.3, 44100)), // not an 11kHz input
    ];

    final zipPath = p.join(dir.path, 'in.zip');
    final count = await exchange.writeInput(
      paths,
      zipPath,
      appVersion: '1.2.3',
    );

    expect(count, 1);
    final zip = readZip(zipPath);
    final hash = sha256.convert(a).toString();
    expect(zip.findFile('wav/$hash.wav')!.content, a);
    final manifest = jsonDecode(
      utf8.decode(zip.findFile('manifest.json')!.content),
    );
    expect(manifest, {
      'appVersion': '1.2.3',
      'modelId': 'test-model',
      'files': [
        {'name': 'A1.WAV', 'sha256': hash},
      ],
    });
  });

  String resultZip(String modelId, Map<String, Uint8List> wavs) {
    final archive = Archive()
      ..add(
        ArchiveFile.string('manifest.json', jsonEncode({'modelId': modelId})),
      );
    wavs.forEach((name, bytes) => archive.add(ArchiveFile.bytes(name, bytes)));
    return write('out.zip', ZipEncoder().encodeBytes(archive));
  }

  test('import puts 44.1kHz results into the cache', () async {
    final hash = 'a' * 64;
    final result = _wav(0.5, 44100);
    final zipPath = resultZip('test-model', {
      'wav/$hash.wav': result,
      'wav/${'b' * 64}.wav': _wav(0.5, 11025), // not enhanced
      'wav/notahash.wav': result,
    });

    expect(await exchange.importResult(zipPath), 1);
    expect(
      File(p.join(exchange.cacheDir, '$hash.wav')).readAsBytesSync(),
      result,
    );
    expect(Directory(exchange.cacheDir).listSync(), hasLength(1));
  });

  test('import rejects results for another model', () async {
    final zipPath = resultZip('other-model', {
      'wav/${'a' * 64}.wav': _wav(0.5, 44100),
    });

    await expectLater(exchange.importResult(zipPath), throwsFormatException);
    expect(Directory(exchange.cacheDir).existsSync(), isFalse);
  });

  test('inspectInput counts the exported voices already imported', () async {
    final a = _wav(0.1, 11025);
    final b = _wav(0.2, 11025);
    final zipPath = p.join(dir.path, 'sr_input.zip');
    await exchange.writeInput(
      [write('A.WAV', a), write('B.WAV', b)],
      zipPath,
      appVersion: '1',
    );
    expect(await exchange.inspectInput(p.join(dir.path, 'none.zip')), isNull);

    var status = (await exchange.inspectInput(zipPath))!;
    expect((status.total, status.imported, status.complete), (2, 0, false));

    File(p.join(exchange.cacheDir, '${sha256.convert(a)}.wav'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(_wav(0.1, 44100));
    status = (await exchange.inspectInput(zipPath))!;
    expect((status.total, status.imported, status.complete), (2, 1, false));
  });

  test('findOutput picks the newest result after the export', () {
    final downloads = Directory(p.join(dir.path, 'dl'))..createSync();
    final export = DateTime(2026, 1, 1, 12);
    File touch(String name, DateTime time) => File(p.join(downloads.path, name))
      ..writeAsStringSync('')
      ..setLastModifiedSync(time);

    touch('sr_output.zip', export.subtract(const Duration(hours: 1)));
    expect(ColabExchange.findOutput([downloads.path], after: export), isNull);

    touch('sr_output (1).zip', export.add(const Duration(minutes: 30)));
    final newest = touch(
      'sr_output (2).zip',
      export.add(const Duration(hours: 1)),
    );
    touch('other.zip', export.add(const Duration(hours: 2)));
    expect(
      ColabExchange.findOutput([downloads.path, '/no/such/dir'], after: export),
      newest.path,
    );
  });
}
