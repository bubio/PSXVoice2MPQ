import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/services/onnx/onnx_runtime.dart';

import '../test/support/vf_post_model.dart';

Float32List _sine(double hz, int n) => Float32List.fromList([
  for (var i = 0; i < n; i++) 0.5 * math.sin(2 * math.pi * hz * i / 44100),
]);

/// RMS of the middle half, away from the filter's edge effects.
double _rms(Float32List x) {
  final mid = x.sublist(x.length ~/ 4, x.length * 3 ~/ 4);
  return math.sqrt(mid.fold(0.0, (s, v) => s + v * v) / mid.length);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Loads ONNX Runtime from the app bundle (placed there by hook/build.dart)
  // and runs vf_post.onnx, which keeps the original audio below 4.8kHz.
  test('bundled ONNX Runtime runs the post-processing model', () async {
    final dir = await Directory.systemTemp.createTemp('ort_');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'vf_post.onnx');
    await File(path).writeAsBytes(base64Decode(vfPostOnnxBase64));

    final runtime = OnnxRuntime.open();
    addTearDown(runtime.dispose);
    final model = runtime.loadModel(path);
    addTearDown(model.dispose);

    const n = 44100;
    double rmsOut(double hz) {
      final out = model.run(
        {
          'orig44k': FloatTensor(_sine(hz, n), [1, 1, n]),
          'vf44k': FloatTensor(Float32List(n), [1, 1, n]),
        },
        ['wav44k'],
      )['wav44k']!;
      expect(out.shape, [1, 1, n]);
      return _rms(out.data);
    }

    final sineRms = 0.5 / math.sqrt2;
    expect(rmsOut(1000), closeTo(sineRms, sineRms * 0.01));
    expect(rmsOut(12000), lessThan(sineRms * 0.01));
  });
}
