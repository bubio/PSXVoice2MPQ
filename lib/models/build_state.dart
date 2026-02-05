/// Build step identifiers for localization
enum BuildStepKey {
  initializing,
  extractingBinaries,
  findingStreamFiles,
  extractingStream,
  convertingVagFiles,
  enhancingAudio,
  convertingToMp3,
  creatingMpq,
  cleaningUp,
  complete,
}

/// Build error identifiers for localization
enum BuildErrorKey {
  smpqNotFound,
  noStreamFiles,
  outputDirectoryNotFound,
  unknown,
}
