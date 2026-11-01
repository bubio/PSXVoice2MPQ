// Bundles the ONNX Runtime shared library as a code asset.
//
// The official prebuilt release archive for the target OS/architecture is
// downloaded, checked against a pinned SHA-256 and the library extracted.
// Archives are cached in the shared output directory across builds.
//
// Offline builds: point the `onnxruntime_library` user define at an already
// extracted library file (path relative to pubspec.yaml), e.g.
//
//   hooks:
//     user_defines:
//       psxvoice2mpq:
//         onnxruntime_library: /path/to/libonnxruntime.1.23.2.dylib
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

const _version = '1.23.2';

/// Asset name; must match the library URI of the generated bindings so the
/// `@Native` functions resolve to this library.
const _assetName = 'src/third_party/onnxruntime.g.dart';

final class _Release {
  /// Release archive file name.
  final String archive;

  /// SHA-256 of [archive].
  final String sha256;

  /// Path of the shared library inside [archive].
  final String library;

  const _Release(this.archive, this.sha256, this.library);
}

_Release _release(OS os, Architecture arch) {
  const v = _version;
  final release = switch ((os, arch)) {
    (OS.macOS, Architecture.arm64) => const _Release(
      'onnxruntime-osx-arm64-$v.tgz',
      'b4d513ab2b26f088c66891dbbc1408166708773d7cc4163de7bdca0e9bbb7856',
      'onnxruntime-osx-arm64-$v/lib/libonnxruntime.$v.dylib',
    ),
    (OS.macOS, Architecture.x64) => const _Release(
      'onnxruntime-osx-x86_64-$v.tgz',
      'd10359e16347b57d9959f7e80a225a5b4a66ed7d7e007274a15cae86836485a6',
      'onnxruntime-osx-x86_64-$v/lib/libonnxruntime.$v.dylib',
    ),
    (OS.linux, Architecture.x64) => const _Release(
      'onnxruntime-linux-x64-$v.tgz',
      '1fa4dcaef22f6f7d5cd81b28c2800414350c10116f5fdd46a2160082551c5f9b',
      'onnxruntime-linux-x64-$v/lib/libonnxruntime.so.$v',
    ),
    (OS.linux, Architecture.arm64) => const _Release(
      'onnxruntime-linux-aarch64-$v.tgz',
      '7c63c73560ed76b1fac6cff8204ffe34fe180e70d6582b5332ec094810241e5c',
      'onnxruntime-linux-aarch64-$v/lib/libonnxruntime.so.$v',
    ),
    (OS.windows, Architecture.x64) => const _Release(
      'onnxruntime-win-x64-$v.zip',
      '0b38df9af21834e41e73d602d90db5cb06dbd1ca618948b8f1d66d607ac9f3cd',
      'onnxruntime-win-x64-$v/lib/onnxruntime.dll',
    ),
    (OS.windows, Architecture.arm64) => const _Release(
      'onnxruntime-win-arm64-$v.zip',
      '1cfe88b6435df3b5fb0e9f6bd7d6f5df1e887b6174de7f6e2a47bab956f3f168',
      'onnxruntime-win-arm64-$v/lib/onnxruntime.dll',
    ),
    _ => null,
  };
  if (release == null) {
    throw UnsupportedError('ONNX Runtime is not available for $os/$arch');
  }
  return release;
}

Future<List<int>> _download(Uri uri) async {
  final client = HttpClient()..findProxy = HttpClient.findProxyFromEnvironment;
  try {
    final response = await (await client.getUrl(uri)).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    return builder.takeBytes();
  } finally {
    client.close();
  }
}

/// Returns the verified archive, downloading it into [cacheDir] if needed.
Future<List<int>> _archive(_Release release, Directory cacheDir) async {
  final file = File.fromUri(cacheDir.uri.resolve(release.archive));
  if (file.existsSync()) {
    final bytes = await file.readAsBytes();
    if (sha256.convert(bytes).toString() == release.sha256) return bytes;
    file.deleteSync();
  }
  final uri = Uri.parse(
    'https://github.com/microsoft/onnxruntime/releases/download/'
    'v$_version/${release.archive}',
  );
  final bytes = await _download(uri);
  final actual = sha256.convert(bytes).toString();
  if (actual != release.sha256) {
    throw StateError(
      'SHA-256 mismatch for $uri: expected ${release.sha256}, got $actual',
    );
  }
  await cacheDir.create(recursive: true);
  final partial = File('${file.path}.part');
  await partial.writeAsBytes(bytes, flush: true);
  await partial.rename(file.path);
  return bytes;
}

List<int> _extract(_Release release, List<int> archive) {
  final decoded = release.archive.endsWith('.zip')
      ? ZipDecoder().decodeBytes(archive)
      : TarDecoder().decodeBytes(GZipDecoder().decodeBytes(archive));
  // Tar entries on macOS start with "./".
  final entry = decoded.files.where(
    (f) => f.name.replaceFirst(RegExp(r'^\./'), '') == release.library,
  );
  if (entry.isEmpty) {
    throw StateError('${release.library} not found in ${release.archive}');
  }
  return entry.first.content;
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    final libraryName = code.targetOS.dylibFileName('onnxruntime');

    final Uri libraryUri;
    final override = input.userDefines.path('onnxruntime_library');
    if (override != null) {
      libraryUri = override;
      output.dependencies.add(override);
    } else {
      final release = _release(code.targetOS, code.targetArchitecture);
      final cacheDir = Directory.fromUri(
        input.outputDirectoryShared.resolve('onnxruntime/'),
      );
      final archive = await _archive(release, cacheDir);
      final library = File.fromUri(input.outputDirectory.resolve(libraryName));
      await library.writeAsBytes(_extract(release, archive), flush: true);
      libraryUri = library.uri;
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: libraryUri,
      ),
    );
  });
}
