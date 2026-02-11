import 'dart:io';

import '../core/constants/path_constants.dart';

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
  String? _ffmpegPath;
  String? _audioSrPath;

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
    final searchPaths = PathConstants.getSearchPaths(name);
    for (final path in searchPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    return null;
  }

  /// Find executable in PATH using 'which' (Unix) or 'where' (Windows).
  /// On macOS/Linux, uses the user's login shell to get the full PATH
  /// (covers Homebrew, MacPorts, Nix, etc.)
  Future<String?> _findInPath(String name) async {
    if (Platform.isWindows) {
      try {
        final result = await Process.run('where', [name]);
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          final firstLine = output.split('\n').first.trim();
          if (firstLine.isNotEmpty) return firstLine;
        }
      } catch (e) {
        // Command not found or other error
      }
      return null;
    }

    // macOS/Linux: use login shell to get full PATH from user's profile
    final shell = Platform.environment['SHELL'] ?? '/bin/sh';
    try {
      final result = await Process.run(
        shell,
        ['-l', '-c', 'command -v $name'],
      );
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) return output;
      }
    } catch (e) {
      // Login shell failed
    }

    // Fallback: try 'which' directly
    try {
      final result = await Process.run('which', [name]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) return output;
      }
    } catch (e) {
      // Command not found or other error
    }
    return null;
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

  Future<String?> findFfmpeg() async {
    if (_ffmpegPath != null) return _ffmpegPath;
    _ffmpegPath = await _findExecutable('ffmpeg');
    return _ffmpegPath;
  }

  Future<String?> findAudioSr() async {
    if (_audioSrPath != null) return _audioSrPath;
    _audioSrPath = await _findExecutable('audiosr');
    return _audioSrPath;
  }

  /// Check if a specific path is a valid audiosr executable
  Future<bool> isValidAudioSr(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Start a long-running process and return the Process object.
  /// The caller is responsible for killing the process when done.
  Future<Process> startProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  }
}
