import 'dart:io';

class StreamMapping {
  final String sourceFile;
  final String destinationPath;

  const StreamMapping({
    required this.sourceFile,
    required this.destinationPath,
  });

  static Future<List<StreamMapping>> loadFromFile(String mapFilePath) async {
    final file = File(mapFilePath);
    if (!await file.exists()) {
      return [];
    }

    final lines = await file.readAsLines();
    final mappings = <StreamMapping>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        mappings.add(StreamMapping(
          sourceFile: parts[0],
          destinationPath: parts[1],
        ));
      }
    }

    return mappings;
  }
}
