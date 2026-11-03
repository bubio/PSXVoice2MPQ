import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/services/super_resolution/wav_io.dart';

void main() {
  group('wav_io', () {
    test('encode then decode keeps sample rate and samples', () {
      final samples = Float32List.fromList([0, 0.5, -0.5, 0.25, -1, 0.999]);
      final decoded = decodePcm16Mono(encodePcm16Mono(samples, 44100))!;

      expect(decoded.sampleRate, 44100);
      expect(decoded.samples.length, samples.length);
      for (var i = 0; i < samples.length; i++) {
        expect(decoded.samples[i], closeTo(samples[i], 1 / 32768));
      }
    });

    test('encode clamps samples outside -1..1', () {
      final decoded = decodePcm16Mono(
        encodePcm16Mono(Float32List.fromList([2, -2]), 11025),
      )!;

      expect(decoded.samples[0], closeTo(1, 1 / 32768));
      expect(decoded.samples[1], -1);
    });

    test('decode rejects stereo and non-WAV data', () {
      final stereo = encodePcm16Mono(Float32List(4), 11025);
      ByteData.sublistView(stereo).setUint16(22, 2, Endian.little);

      expect(decodePcm16Mono(stereo), isNull);
      expect(
        decodePcm16Mono(Uint8List.fromList('not a wav'.codeUnits)),
        isNull,
      );
    });

    test('decode skips chunks before fmt and data', () {
      final wav = encodePcm16Mono(Float32List.fromList([0.5]), 11025);
      // Insert an odd-sized LIST chunk (padded to even) after "WAVE".
      final list = [...'LIST'.codeUnits, 3, 0, 0, 0, 1, 2, 3, 0];
      final withList = Uint8List.fromList([
        ...wav.sublist(0, 12),
        ...list,
        ...wav.sublist(12),
      ]);

      final decoded = decodePcm16Mono(withList)!;
      expect(decoded.samples.single, closeTo(0.5, 1 / 32768));
    });
  });
}
