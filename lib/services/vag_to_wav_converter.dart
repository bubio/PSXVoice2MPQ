import 'dart:io';
import 'dart:typed_data';

/// Converts PlayStation VAG audio files to WAV format.
/// Based on VAG-Depack by bITmASTER.
class VagToWavConverter {
  // ADPCM filter coefficients
  static const List<List<double>> _filterCoeffs = [
    [0.0, 0.0],
    [60.0 / 64.0, 0.0],
    [115.0 / 64.0, -52.0 / 64.0],
    [98.0 / 64.0, -55.0 / 64.0],
    [122.0 / 64.0, -60.0 / 64.0],
  ];

  /// Converts a VAG file to WAV format.
  ///
  /// [gain] multiplies PCM sample amplitude (e.g. 2.0 = +6 dB).
  /// Returns a [VagConversionResult] indicating success or failure.
  Future<VagConversionResult> convert(
    String vagPath,
    String wavPath, {
    double gain = 1.0,
  }) async {
    final vagFile = File(vagPath);

    if (!await vagFile.exists()) {
      return VagConversionResult.failure('VAG file not found: $vagPath');
    }

    try {
      final vagData = await vagFile.readAsBytes();
      final wavData = _convertVagToWav(vagData, gain: gain);

      if (wavData == null) {
        return VagConversionResult.failure('Invalid VAG file format');
      }

      final wavFile = File(wavPath);
      await wavFile.writeAsBytes(wavData);

      return VagConversionResult.success();
    } catch (e) {
      return VagConversionResult.failure('Conversion error: $e');
    }
  }

  /// Converts VAG data to WAV data in memory.
  ///
  /// [gain] multiplies PCM sample amplitude (e.g. 2.0 = +6 dB).
  /// Returns the WAV data as Uint8List, or null if the VAG data is invalid.
  Uint8List? convertBytes(Uint8List vagData, {double gain = 1.0}) {
    return _convertVagToWav(vagData, gain: gain);
  }

  Uint8List? _convertVagToWav(Uint8List vagData, {double gain = 1.0}) {
    // Verify VAG header magic
    if (vagData.length < 64) {
      return null;
    }

    final magic = String.fromCharCodes(vagData.sublist(0, 4));
    if (magic != 'VAGp') {
      return null;
    }

    // Read header fields (big-endian)
    final dataSize = _readBigEndian32(vagData, 12);
    final sampleRate = _readBigEndian32(vagData, 16);

    // Decode ADPCM data
    final pcmSamples = _decodeAdpcm(vagData, 64, dataSize);

    // Build WAV file
    return _buildWav(pcmSamples, sampleRate, gain: gain);
  }

  int _readBigEndian32(Uint8List data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  List<int> _decodeAdpcm(Uint8List vagData, int startOffset, int dataSize) {
    final samples = <int>[];
    double s1 = 0.0;
    double s2 = 0.0;

    int offset = startOffset;
    final endOffset = startOffset + dataSize;

    while (offset < endOffset && offset + 16 <= vagData.length) {
      final predictByte = vagData[offset];
      final shiftFactor = predictByte & 0x0F;
      final predictNr = (predictByte >> 4) & 0x0F;
      final flags = vagData[offset + 1];

      // Check for end flag
      if (flags == 7) {
        break;
      }

      // Ensure predict_nr is within bounds
      final filterIndex = predictNr < 5 ? predictNr : 0;

      // Decode 28 samples from 14 bytes
      final decodedSamples = List<double>.filled(28, 0.0);

      for (int i = 0; i < 28; i += 2) {
        final d = vagData[offset + 2 + (i ~/ 2)];

        // Low nibble - sign extend from 16-bit
        int s = ((d & 0x0F) << 12).toSigned(16);
        decodedSamples[i] = (s >> shiftFactor).toDouble();

        // High nibble - sign extend from 16-bit
        s = ((d & 0xF0) << 8).toSigned(16);
        decodedSamples[i + 1] = (s >> shiftFactor).toDouble();
      }

      // Apply filter and output samples
      for (int i = 0; i < 28; i++) {
        decodedSamples[i] =
            decodedSamples[i] +
            s1 * _filterCoeffs[filterIndex][0] +
            s2 * _filterCoeffs[filterIndex][1];
        s2 = s1;
        s1 = decodedSamples[i];

        // Clip to 16-bit range
        final clipped = _clipInt16((decodedSamples[i] + 0.5).toInt());
        samples.add(clipped);
      }

      offset += 16; // Each ADPCM block is 16 bytes
    }

    return samples;
  }

  int _clipInt16(int value) {
    if ((value + 0x8000) & ~0xFFFF != 0) {
      return (value >> 31) ^ 0x7FFF;
    }
    return value;
  }

  Uint8List _buildWav(List<int> samples, int sampleRate, {double gain = 1.0}) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2; // 16-bit samples
    final fileSize = 44 + dataSize;

    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // 'R'
    buffer.setUint8(offset++, 0x49); // 'I'
    buffer.setUint8(offset++, 0x46); // 'F'
    buffer.setUint8(offset++, 0x46); // 'F'

    // File size - 8
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;

    // WAVE
    buffer.setUint8(offset++, 0x57); // 'W'
    buffer.setUint8(offset++, 0x41); // 'A'
    buffer.setUint8(offset++, 0x56); // 'V'
    buffer.setUint8(offset++, 0x45); // 'E'

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // 'f'
    buffer.setUint8(offset++, 0x6D); // 'm'
    buffer.setUint8(offset++, 0x74); // 't'
    buffer.setUint8(offset++, 0x20); // ' '

    // Chunk size (16 for PCM)
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;

    // Audio format (1 = PCM)
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;

    // Number of channels (1 = mono)
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;

    // Sample rate
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;

    // Byte rate (SampleRate * NumChannels * BitsPerSample/8)
    buffer.setUint32(offset, sampleRate * 2, Endian.little);
    offset += 4;

    // Block align (NumChannels * BitsPerSample/8)
    buffer.setUint16(offset, 2, Endian.little);
    offset += 2;

    // Bits per sample
    buffer.setUint16(offset, 16, Endian.little);
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // 'd'
    buffer.setUint8(offset++, 0x61); // 'a'
    buffer.setUint8(offset++, 0x74); // 't'
    buffer.setUint8(offset++, 0x61); // 'a'

    // Data size
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Write PCM samples
    for (final sample in samples) {
      int s = sample;
      if (gain != 1.0) {
        s = _clipInt16((sample * gain).round());
      }
      buffer.setInt16(offset, s, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}

/// Result of a VAG to WAV conversion operation.
class VagConversionResult {
  final bool isSuccess;
  final String? errorMessage;

  VagConversionResult._({required this.isSuccess, this.errorMessage});

  factory VagConversionResult.success() =>
      VagConversionResult._(isSuccess: true);

  factory VagConversionResult.failure(String message) =>
      VagConversionResult._(isSuccess: false, errorMessage: message);
}
