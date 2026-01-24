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
  static const List<String> _smpqSearchPaths = [
    '/usr/local/bin/smpq',
    '/opt/homebrew/bin/smpq',
    '/usr/bin/smpq',
  ];

  String? _smpqPath;

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

  Future<String?> findSmpq() async {
    if (_smpqPath != null) return _smpqPath;

    for (final path in _smpqSearchPaths) {
      if (await File(path).exists()) {
        _smpqPath = path;
        return path;
      }
    }
    return null;
  }

  Future<bool> isCommandAvailable(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
