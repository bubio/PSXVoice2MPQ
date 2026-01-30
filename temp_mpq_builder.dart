import 'dart:io';
import 'lib/services/pure_dart_mpq_builder.dart';

void main() async {
  final builder = PureDartMpqBuilder();

  final inputFiles = [
    MpqFileEntry(
      sourcePath: '/Users/seiji/dev/flutter/PSXVoice2MPQ/assets/test/J00ED.WAV',
      archivePath: 'sfx\towners\cow8.wav',
    ),
    MpqFileEntry(
      sourcePath: '/Users/seiji/dev/flutter/PSXVoice2MPQ/assets/test/J02B1.WAV',
      archivePath: 'sfx\rogue\rogue77.wav',
    ),
  ];

  final outputPath = '/Users/seiji/dev/flutter/PSXVoice2MPQ/temp_generated_ja.mpq';

  print('Creating MPQ: $outputPath');
  final result = await builder.createArchive(outputPath, inputFiles);

  if (result.isSuccess) {
    print('MPQ created successfully: ${result.mpqPath}');
  } else {
    print('Failed to create MPQ: ${result.errorMessage}');
  }
}

