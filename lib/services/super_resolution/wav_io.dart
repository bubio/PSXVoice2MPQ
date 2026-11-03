import 'dart:typed_data';

/// Mono float samples (-1.0..1.0) with their sample rate.
typedef MonoAudio = ({Float32List samples, int sampleRate});

/// Decodes a 16-bit PCM mono WAV file. Returns null for any other format.
MonoAudio? decodePcm16Mono(Uint8List bytes) {
  if (bytes.length < 12 ||
      String.fromCharCodes(bytes, 0, 4) != 'RIFF' ||
      String.fromCharCodes(bytes, 8, 12) != 'WAVE') {
    return null;
  }
  final data = ByteData.sublistView(bytes);
  int? sampleRate;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes, offset, offset + 4);
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ' && size >= 16) {
      final format = data.getUint16(body, Endian.little);
      final channels = data.getUint16(body + 2, Endian.little);
      final bits = data.getUint16(body + 14, Endian.little);
      if (format != 1 || channels != 1 || bits != 16) return null;
      sampleRate = data.getUint32(body + 4, Endian.little);
    } else if (id == 'data' && sampleRate != null) {
      final count = (size.clamp(0, bytes.length - body)) ~/ 2;
      final samples = Float32List(count);
      for (var i = 0; i < count; i++) {
        samples[i] = data.getInt16(body + i * 2, Endian.little) / 32768.0;
      }
      return (samples: samples, sampleRate: sampleRate);
    }
    offset = body + size + (size & 1);
  }
  return null;
}

/// Encodes [samples] (-1.0..1.0) as a 16-bit PCM mono WAV file.
Uint8List encodePcm16Mono(Float32List samples, int sampleRate) {
  final dataSize = samples.length * 2;
  final bytes = Uint8List(44 + dataSize);
  final out = ByteData.sublistView(bytes);
  void tag(int at, String s) => bytes.setAll(at, s.codeUnits);
  tag(0, 'RIFF');
  out.setUint32(4, 36 + dataSize, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little); // PCM
  out.setUint16(22, 1, Endian.little); // mono
  out.setUint32(24, sampleRate, Endian.little);
  out.setUint32(28, sampleRate * 2, Endian.little);
  out.setUint16(32, 2, Endian.little);
  out.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  out.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    // Same scale as decodePcm16Mono, so decoding the result round-trips.
    final v = (samples[i] * 32768.0).round().clamp(-32768, 32767);
    out.setInt16(44 + i * 2, v, Endian.little);
  }
  return bytes;
}
