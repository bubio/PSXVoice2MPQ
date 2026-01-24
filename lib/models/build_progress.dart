class BuildProgress {
  final String currentStep;
  final String currentFile;
  final int totalFiles;
  final int processedFiles;
  final double percentage;
  final List<String> logs;
  final bool isComplete;
  final String? error;

  const BuildProgress({
    required this.currentStep,
    this.currentFile = '',
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.percentage = 0.0,
    this.logs = const [],
    this.isComplete = false,
    this.error,
  });

  BuildProgress copyWith({
    String? currentStep,
    String? currentFile,
    int? totalFiles,
    int? processedFiles,
    double? percentage,
    List<String>? logs,
    bool? isComplete,
    String? error,
  }) {
    return BuildProgress(
      currentStep: currentStep ?? this.currentStep,
      currentFile: currentFile ?? this.currentFile,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      percentage: percentage ?? this.percentage,
      logs: logs ?? this.logs,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }

  BuildProgress addLog(String message) {
    return copyWith(logs: [...logs, message]);
  }
}
