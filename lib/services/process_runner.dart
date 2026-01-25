import 'dart:io';

class ProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;
}

class ProcessRunner {
  String? _smpqPath;
  String? _lamePath;

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );

    return ProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  /// Find an executable in PATH or common installation directories
  Future<String?> _findExecutable(String name) async {
    // First, try to find in PATH using platform-specific command
    final pathResult = await _findInPath(name);
    if (pathResult != null) return pathResult;

    // Then check common installation directories
    final searchPaths = _getSearchPaths(name);
    for (final path in searchPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    return null;
  }

  /// Find executable in PATH using 'which' (Unix) or 'where' (Windows)
  Future<String?> _findInPath(String name) async {
    try {
      final command = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(command, [name]);
      if (result.exitCode == 0) {
        // 'where' on Windows may return multiple lines, take the first one
        final output = result.stdout.toString().trim();
        final firstLine = output.split('\n').first.trim();
        if (firstLine.isNotEmpty) {
          return firstLine;
        }
      }
    } catch (e) {
      // Command not found or other error
    }
    return null;
  }

  /// Get platform-specific search paths for an executable
  List<String> _getSearchPaths(String name) {
    final paths = <String>[];
    final execName = Platform.isWindows ? '$name.exe' : name;

    if (Platform.isWindows) {
      final programFiles = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
      final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';

      paths.addAll([
        '$programFiles\\StormLib\\$execName',
        '$programFilesX86\\StormLib\\$execName',
        '$localAppData\\StormLib\\$execName',
        '$programFiles\\smpq\\$execName',
        '$programFilesX86\\smpq\\$execName',
      ]);
    } else if (Platform.isMacOS) {
      paths.addAll([
        '/opt/homebrew/bin/$name',
        '/usr/local/bin/$name',
        '/usr/bin/$name',
      ]);
    } else {
      // Linux
      final home = Platform.environment['HOME'] ?? '';
      paths.addAll([
        '/usr/local/bin/$name',
        '/usr/bin/$name',
        '$home/.local/bin/$name',
        '/snap/bin/$name',
      ]);
    }

    return paths;
  }

  Future<String?> findSmpq() async {
    if (_smpqPath != null) return _smpqPath;
    _smpqPath = await _findExecutable('smpq');
    return _smpqPath;
  }

  Future<String?> findLame() async {
    if (_lamePath != null) return _lamePath;
    _lamePath = await _findExecutable('lame');
    return _lamePath;
  }
}
