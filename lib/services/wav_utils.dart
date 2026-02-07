import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// Splits a WAV file into chunks of [chunkSeconds] seconds each.
///
/// When [overlapSeconds] > 0, consecutive chunks overlap by that duration,
/// enabling crossfade-based concatenation to eliminate boundary artifacts.
///
/// Returns a list of paths to the generated chunk files.
/// Files are named `basename_000.WAV`, `basename_001.WAV`, etc.
Future<List<String>> splitWav(
  String inputPath,
  String outputDir,
  int chunkSeconds, {
  double overlapSeconds = 0,
}) async {
  final file = File(inputPath);
  final bytes = await file.readAsBytes();
  final data = ByteData.sublistView(bytes);

  // Parse WAV header (44 bytes for standard PCM WAV)
  // Bytes 22-23: numChannels
  final numChannels = data.getUint16(22, Endian.little);
  // Bytes 24-27: sampleRate
  final sampleRate = data.getUint32(24, Endian.little);
  // Bytes 34-35: bitsPerSample
  final bitsPerSample = data.getUint16(34, Endian.little);

  final bytesPerSample = bitsPerSample ~/ 8;
  final blockAlign = numChannels * bytesPerSample;
  final chunkByteSize = sampleRate * chunkSeconds * blockAlign;
  final overlapByteSize = (sampleRate * overlapSeconds).round() * blockAlign;
  final stride = chunkByteSize - overlapByteSize;

  // Find the data chunk offset and size
  int dataOffset = 12; // Skip RIFF header (12 bytes)
  int dataSize = 0;
  while (dataOffset < bytes.length - 8) {
    final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
    final chunkSize = data.getUint32(dataOffset + 4, Endian.little);
    if (chunkId == 'data') {
      dataOffset += 8; // Skip chunk ID and size
      dataSize = chunkSize;
      break;
    }
    dataOffset += 8 + chunkSize;
  }

  if (dataSize == 0) {
    throw Exception('No data chunk found in WAV file: $inputPath');
  }

  final pcmData = bytes.sublist(dataOffset, dataOffset + dataSize);

  final baseName = p.basenameWithoutExtension(inputPath);
  final results = <String>[];
  int offset = 0;
  int index = 0;

  while (offset < pcmData.length) {
    final end = (offset + chunkByteSize).clamp(0, pcmData.length);
    final chunkData = pcmData.sublist(offset, end);

    final chunkFileName =
        '${baseName}_${index.toString().padLeft(3, '0')}.WAV';
    final chunkPath = p.join(outputDir, chunkFileName);

    await _writeWav(
      chunkPath,
      chunkData,
      numChannels: numChannels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
    );

    results.add(chunkPath);
    offset += stride;
    if (end >= pcmData.length) break;
    index++;
  }

  return results;
}

/// Concatenates multiple WAV files into a single output WAV file.
///
/// Uses the format from the first file for the output header.
Future<void> concatenateWav(
  List<String> inputPaths,
  String outputPath,
) async {
  if (inputPaths.isEmpty) return;

  // Read header info from the first file
  final firstBytes = await File(inputPaths.first).readAsBytes();
  final firstData = ByteData.sublistView(firstBytes);
  final numChannels = firstData.getUint16(22, Endian.little);
  final sampleRate = firstData.getUint32(24, Endian.little);
  final bitsPerSample = firstData.getUint16(34, Endian.little);

  // Collect all PCM data
  final allPcm = <int>[];
  for (final path in inputPaths) {
    final bytes = await File(path).readAsBytes();
    final data = ByteData.sublistView(bytes);

    // Find data chunk
    int offset = 12;
    while (offset < bytes.length - 8) {
      final chunkId =
          String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      if (chunkId == 'data') {
        offset += 8;
        allPcm.addAll(bytes.sublist(offset, offset + chunkSize));
        break;
      }
      offset += 8 + chunkSize;
    }
  }

  await _writeWav(
    outputPath,
    Uint8List.fromList(allPcm),
    numChannels: numChannels,
    sampleRate: sampleRate,
    bitsPerSample: bitsPerSample,
  );
}

/// Concatenates WAV files with linear crossfade blending in overlap regions.
///
/// Each chunk after the first has its leading [crossfadeFrames] frames blended
/// with the trailing frames of the previous chunk using linear interpolation.
/// This eliminates discontinuities at chunk boundaries.
Future<void> concatenateWavCrossfade(
  List<String> inputPaths,
  String outputPath,
  int crossfadeFrames,
) async {
  if (inputPaths.isEmpty) return;

  // Read header info from the first file
  final firstBytes = await File(inputPaths.first).readAsBytes();
  final firstData = ByteData.sublistView(firstBytes);
  final numChannels = firstData.getUint16(22, Endian.little);
  final sampleRate = firstData.getUint32(24, Endian.little);
  final bitsPerSample = firstData.getUint16(34, Endian.little);
  final bytesPerSample = bitsPerSample ~/ 8;
  final blockAlign = numChannels * bytesPerSample;

  // Helper: extract PCM as Int16 sample list from a WAV file
  Future<List<int>> readPcmSamples(String path) async {
    final bytes = await File(path).readAsBytes();
    final bd = ByteData.sublistView(bytes);
    int offset = 12;
    while (offset < bytes.length - 8) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = bd.getUint32(offset + 4, Endian.little);
      if (id == 'data') {
        offset += 8;
        final sampleCount = size ~/ bytesPerSample;
        final samples = List<int>.filled(sampleCount, 0);
        for (int i = 0; i < sampleCount; i++) {
          samples[i] = bd.getInt16(offset + i * bytesPerSample, Endian.little);
        }
        return samples;
      }
      offset += 8 + size;
    }
    return [];
  }

  // Read all chunks as sample arrays
  final chunks = <List<int>>[];
  for (final path in inputPaths) {
    chunks.add(await readPcmSamples(path));
  }

  // Build output by appending chunks with crossfade blending
  final output = <int>[];
  final crossfadeSamples = crossfadeFrames * numChannels;

  for (int c = 0; c < chunks.length; c++) {
    final chunk = chunks[c];
    if (c == 0) {
      output.addAll(chunk);
    } else {
      final fadeLen = math.min(crossfadeSamples, math.min(output.length, chunk.length));
      // Blend the overlap region
      for (int s = 0; s < fadeLen; s++) {
        final frame = s ~/ numChannels;
        final t = (frame + 1) / (crossfadeFrames + 1);
        final prevIdx = output.length - fadeLen + s;
        final blended = (output[prevIdx] * (1 - t) + chunk[s] * t).round();
        output[prevIdx] = blended.clamp(-32768, 32767);
      }
      // Append the non-overlapping tail
      if (fadeLen < chunk.length) {
        output.addAll(chunk.sublist(fadeLen));
      }
    }
  }

  // Write output as 16-bit PCM WAV
  final outDataSize = output.length * bytesPerSample;
  final outPcm = ByteData(outDataSize);
  for (int i = 0; i < output.length; i++) {
    outPcm.setInt16(i * bytesPerSample, output[i], Endian.little);
  }

  await _writeWav(
    outputPath,
    outPcm.buffer.asUint8List(),
    numChannels: numChannels,
    sampleRate: sampleRate,
    bitsPerSample: bitsPerSample,
  );
}

/// Resamples a WAV file to a target sample rate using band-limited sinc
/// interpolation with a Lanczos window (a=5).
Future<void> resampleWav(
  String inputPath,
  String outputPath,
  int targetSampleRate,
) async {
  final file = File(inputPath);
  final bytes = await file.readAsBytes();
  final data = ByteData.sublistView(bytes);

  final numChannels = data.getUint16(22, Endian.little);
  final sampleRate = data.getUint32(24, Endian.little);
  final bitsPerSample = data.getUint16(34, Endian.little);

  if (sampleRate == targetSampleRate) {
    await file.copy(outputPath);
    return;
  }

  // Find data chunk
  int dataOffset = 12;
  int dataSize = 0;
  while (dataOffset < bytes.length - 8) {
    final chunkId =
        String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
    final chunkSize = data.getUint32(dataOffset + 4, Endian.little);
    if (chunkId == 'data') {
      dataOffset += 8;
      dataSize = chunkSize;
      break;
    }
    dataOffset += 8 + chunkSize;
  }

  if (dataSize == 0) {
    throw Exception('No data chunk found in WAV file: $inputPath');
  }

  final bytesPerSample = bitsPerSample ~/ 8;
  final blockAlign = numChannels * bytesPerSample;
  final numFrames = dataSize ~/ blockAlign;
  final pcmBytes = bytes.sublist(dataOffset, dataOffset + dataSize);
  final pcmData = ByteData.sublistView(Uint8List.fromList(pcmBytes));

  // Read input samples (16-bit signed)
  final inputSamples = List<List<double>>.generate(numChannels, (_) => []);
  for (int i = 0; i < numFrames; i++) {
    for (int ch = 0; ch < numChannels; ch++) {
      final offset = (i * numChannels + ch) * bytesPerSample;
      final sample = pcmData.getInt16(offset, Endian.little);
      inputSamples[ch].add(sample.toDouble());
    }
  }

  // Resample using Lanczos interpolation (a=5)
  final ratio = targetSampleRate / sampleRate;
  final outputFrames = (numFrames * ratio).round();
  const a = 5; // Lanczos window parameter (half-width)

  final outputSamples = List<List<double>>.generate(numChannels, (_) => []);

  for (int ch = 0; ch < numChannels; ch++) {
    final input = inputSamples[ch];
    final output = List<double>.filled(outputFrames, 0.0);

    for (int j = 0; j < outputFrames; j++) {
      final srcPos = j / ratio;
      final srcIndex = srcPos.floor();
      double sum = 0.0;

      for (int k = srcIndex - a + 1; k <= srcIndex + a; k++) {
        if (k < 0 || k >= numFrames) continue;
        final x = srcPos - k;
        final w = _lanczos(x, a);
        sum += input[k] * w;
      }

      output[j] = sum;
    }

    outputSamples[ch] = output;
  }

  // Write output PCM (16-bit signed, clamped)
  final outputDataSize = outputFrames * blockAlign;
  final outputPcm = ByteData(outputDataSize);

  for (int i = 0; i < outputFrames; i++) {
    for (int ch = 0; ch < numChannels; ch++) {
      final sample = outputSamples[ch][i].round().clamp(-32768, 32767);
      final offset = (i * numChannels + ch) * bytesPerSample;
      outputPcm.setInt16(offset, sample, Endian.little);
    }
  }

  await _writeWav(
    outputPath,
    outputPcm.buffer.asUint8List(),
    numChannels: numChannels,
    sampleRate: targetSampleRate,
    bitsPerSample: bitsPerSample,
  );
}

/// Lanczos kernel: sinc(x) * sinc(x/a) for |x| < a, else 0.
double _lanczos(double x, int a) {
  if (x == 0.0) return 1.0;
  if (x.abs() >= a) return 0.0;
  final px = math.pi * x;
  return (math.sin(px) / px) * (math.sin(px / a) / (px / a));
}

/// Writes PCM data with a standard WAV header.
Future<void> _writeWav(
  String path,
  Uint8List pcmData, {
  required int numChannels,
  required int sampleRate,
  required int bitsPerSample,
}) async {
  final bytesPerSample = bitsPerSample ~/ 8;
  final blockAlign = numChannels * bytesPerSample;
  final byteRate = sampleRate * blockAlign;
  final dataSize = pcmData.length;
  final fileSize = 36 + dataSize;

  final header = ByteData(44);
  // RIFF header
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, fileSize, Endian.little);
  header.setUint8(8, 0x57); // W
  header.setUint8(9, 0x41); // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E

  // fmt subchunk
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6D); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // (space)
  header.setUint32(16, 16, Endian.little); // Subchunk1Size (PCM)
  header.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, dataSize, Endian.little);

  final file = File(path);
  final sink = file.openWrite();
  sink.add(header.buffer.asUint8List());
  sink.add(pcmData);
  await sink.close();
}
