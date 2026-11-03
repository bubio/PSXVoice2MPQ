import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/main.dart';

void main() {
  test('registers VoiceFixer and ONNX Runtime licenses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerExternalLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((e) => e.packages).toSet();
    expect(packages, containsAll(['StormLib', 'VoiceFixer', 'ONNX Runtime']));

    final ort = entries.where((e) => e.packages.contains('ONNX Runtime'));
    final text = ort
        .expand((e) => e.paragraphs)
        .map((p) => p.text)
        .join('\n');
    expect(text, contains('Copyright (c) Microsoft Corporation'));
    expect(text, contains('THIRD PARTY SOFTWARE NOTICES'));
  });
}
