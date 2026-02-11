import 'build_state.dart';
export 'build_state.dart';

class BuildProgress {
  final String currentStep;
  final BuildStepKey? stepKey;
  final String? streamName;
  final String currentFile;
  final int totalFiles;
  final int processedFiles;
  final double percentage;
  final List<String> logs;
  final bool isComplete;
  final String? error;
  final BuildErrorKey? errorKey;

  const BuildProgress({
    required this.currentStep,
    this.stepKey,
    this.streamName,
    this.currentFile = '',
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.percentage = 0.0,
    this.logs = const [],
    this.isComplete = false,
    this.error,
    this.errorKey,
  });

  BuildProgress copyWith({
    String? currentStep,
    BuildStepKey? stepKey,
    String? streamName,
    String? currentFile,
    int? totalFiles,
    int? processedFiles,
    double? percentage,
    List<String>? logs,
    bool? isComplete,
    String? error,
    BuildErrorKey? errorKey,
  }) {
    return BuildProgress(
      currentStep: currentStep ?? this.currentStep,
      stepKey: stepKey ?? this.stepKey,
      streamName: streamName ?? this.streamName,
      currentFile: currentFile ?? this.currentFile,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      percentage: percentage ?? this.percentage,
      logs: logs ?? this.logs,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
      errorKey: errorKey ?? this.errorKey,
    );
  }

  BuildProgress addLog(String message) {
    return copyWith(logs: [...logs, message]);
  }
}
