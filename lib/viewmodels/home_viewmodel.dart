import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../core/constants/path_constants.dart';
import '../core/di/service_locator.dart';
import '../models/build_progress.dart';
import '../services/mpq_builder_service.dart';
import '../services/settings_service.dart';
import '../services/super_resolution/colab_exchange.dart';
import '../services/super_resolution/model_downloader.dart';
import '../services/super_resolution/super_resolution_service.dart';

/// Build status enum
enum BuildStatus { idle, building, completed, error }

/// Home screen state
class HomeState {
  final String assetsPath;
  final String outputPath;
  final BuildStatus status;
  final BuildProgress? progress;
  final Locale? locale;

  /// Whether the user turned super-resolution on.
  final bool useSuperResolution;

  /// Whether the super-resolution model is installed.
  final bool superResolutionAvailable;

  /// Whether super-resolution runs on Google Colab (results are imported
  /// into the cache) instead of in the app.
  final bool superResolutionOnColab;

  /// Download progress (0..1) of the model, or null when not downloading.
  final double? modelDownloadProgress;

  /// Error from the last model download, if it failed.
  final String? modelDownloadError;

  /// The `sr_input.zip` in the output folder, if one was exported.
  final ColabInputStatus? colabInput;

  /// A notebook result (`sr_output*.zip`) newer than [colabInput] that has
  /// not been imported yet.
  final String? colabResultPath;

  const HomeState({
    required this.assetsPath,
    required this.outputPath,
    required this.status,
    this.progress,
    this.locale,
    this.useSuperResolution = false,
    this.superResolutionAvailable = false,
    this.superResolutionOnColab = false,
    this.modelDownloadProgress,
    this.modelDownloadError,
    this.colabInput,
    this.colabResultPath,
  });

  factory HomeState.initial() {
    return HomeState(
      assetsPath: '',
      outputPath: PathConstants.getDefaultOutputPath() ?? '',
      status: BuildStatus.idle,
    );
  }

  bool get canBuild =>
      assetsPath.isNotEmpty &&
      outputPath.isNotEmpty &&
      status != BuildStatus.building;

  bool get isBuilding => status == BuildStatus.building;

  /// Whether the next build runs super-resolution.
  bool get superResolutionActive =>
      useSuperResolution &&
      (superResolutionOnColab || superResolutionAvailable);

  SuperResolutionMode get superResolutionMode => !superResolutionActive
      ? SuperResolutionMode.off
      : superResolutionOnColab
      ? SuperResolutionMode.colab
      : SuperResolutionMode.local;

  HomeState copyWith({
    String? assetsPath,
    String? outputPath,
    BuildStatus? status,
    BuildProgress? progress,
    Locale? locale,
    bool? useSuperResolution,
    bool? superResolutionAvailable,
    bool? superResolutionOnColab,
    double? modelDownloadProgress,
    String? modelDownloadError,
    bool clearProgress = false,
    bool clearModelDownload = false,
    (ColabInputStatus?, String?)? colab,
  }) {
    return HomeState(
      assetsPath: assetsPath ?? this.assetsPath,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      progress: clearProgress ? null : (progress ?? this.progress),
      locale: locale ?? this.locale,
      useSuperResolution: useSuperResolution ?? this.useSuperResolution,
      superResolutionAvailable:
          superResolutionAvailable ?? this.superResolutionAvailable,
      superResolutionOnColab:
          superResolutionOnColab ?? this.superResolutionOnColab,
      modelDownloadProgress: clearModelDownload
          ? null
          : (modelDownloadProgress ?? this.modelDownloadProgress),
      modelDownloadError: clearModelDownload
          ? null
          : (modelDownloadError ?? this.modelDownloadError),
      colabInput: colab == null ? colabInput : colab.$1,
      colabResultPath: colab == null ? colabResultPath : colab.$2,
    );
  }
}

/// HomeViewModel using Riverpod Notifier
class HomeViewModel extends Notifier<HomeState> {
  final MpqBuilderService _builderService;
  final SettingsService _settingsService;
  final SuperResolutionService _superResolution;
  StreamSubscription<BuildProgress>? _buildSubscription;
  ModelDownloader? _modelDownloader;

  /// Result zips already imported, so they are not offered again.
  final _importedResults = <String>{};

  HomeViewModel(
    this._builderService,
    this._settingsService,
    this._superResolution,
  );

  @override
  HomeState build() {
    ref.onDispose(_dispose);
    _initSuperResolution();
    return HomeState.initial();
  }

  Future<void> _initSuperResolution() async {
    final enabled = await _settingsService.getSuperResolutionEnabled();
    final onColab = await _settingsService.getSuperResolutionOnColab();
    state = state.copyWith(
      useSuperResolution: enabled,
      superResolutionOnColab: onColab,
      superResolutionAvailable: _superResolution.isModelInstalled,
    );
    await refreshColabStatus();
  }

  /// Re-reads the exported `sr_input.zip` and looks for a notebook result in
  /// the Downloads and output folders.
  Future<void> refreshColabStatus() async {
    final output = state.outputPath;
    final exchange = ColabExchange(cacheDir: _superResolution.cacheDir);
    final input = output.isEmpty
        ? null
        : await exchange.inspectInput(
            p.join(output, ColabExchange.inputZipName),
          );
    String? result;
    if (input != null && !input.complete) {
      result = ColabExchange.findOutput([
        ?ColabExchange.downloadsDir(),
        output,
      ], after: input.modified);
      if (_importedResults.contains(result)) result = null;
    }
    if (output == state.outputPath) {
      state = state.copyWith(colab: (input, result));
    }
  }

  /// Re-checks whether the model is installed (e.g. after a download).
  void refreshSuperResolutionAvailability() {
    state = state.copyWith(
      superResolutionAvailable: _superResolution.isModelInstalled,
    );
  }

  /// Downloads the super-resolution model and enables it on success.
  Future<void> downloadModel() async {
    if (_modelDownloader != null) return;
    final downloader = _modelDownloader = ModelDownloader(
      _superResolution.modelDir,
    );
    state = state.copyWith(clearModelDownload: true, modelDownloadProgress: 0);
    try {
      await downloader.download(
        onProgress: (v) => state = state.copyWith(modelDownloadProgress: v),
      );
      state = state.copyWith(
        clearModelDownload: true,
        superResolutionAvailable: _superResolution.isModelInstalled,
      );
      await setUseSuperResolution(true);
    } on ModelDownloadCancelled {
      state = state.copyWith(clearModelDownload: true);
    } catch (e) {
      state = state.copyWith(
        clearModelDownload: true,
        modelDownloadError: e.toString(),
      );
    } finally {
      _modelDownloader = null;
    }
  }

  /// Stops [downloadModel]; the next download resumes where it stopped.
  void cancelModelDownload() => _modelDownloader?.cancel();

  Future<void> setUseSuperResolution(bool value) async {
    state = state.copyWith(useSuperResolution: value);
    await _settingsService.setSuperResolutionEnabled(value);
  }

  Future<void> setSuperResolutionOnColab(bool value) async {
    state = state.copyWith(superResolutionOnColab: value);
    await _settingsService.setSuperResolutionOnColab(value);
  }

  /// Writes the voices that still need super-resolution to `sr_input.zip`
  /// in the output folder, for the Colab notebook.
  Future<void> exportForColab() async {
    if (!state.canBuild) return;
    final info = await PackageInfo.fromPlatform();
    _listenToBuild(
      _builderService.exportForColab(
        state.assetsPath,
        state.outputPath,
        appVersion: info.version,
      ),
    );
  }

  /// Copies the results in the notebook's `sr_output.zip` into the cache and
  /// starts a build that uses them. Returns the number of files imported.
  Future<int> importColabResultAndBuild(String zipPath) async {
    final count = await ColabExchange(cacheDir: _superResolution.cacheDir)
        .importResult(zipPath);
    _importedResults.add(zipPath);
    await refreshColabStatus();
    await startBuild();
    return count;
  }

  void setAssetsPath(String path) {
    state = state.copyWith(assetsPath: path);
  }

  void setOutputPath(String path) {
    state = state.copyWith(outputPath: path);
    refreshColabStatus();
  }

  void setLocale(Locale? locale) {
    state = state.copyWith(locale: locale);
  }

  Future<void> startBuild() async {
    if (!state.canBuild) return;
    _listenToBuild(
      _builderService.build(
        state.assetsPath,
        state.outputPath,
        superResolution: state.superResolutionMode,
      ),
    );
  }

  void _listenToBuild(Stream<BuildProgress> stream) {
    state = state.copyWith(
      status: BuildStatus.building,
      progress: BuildProgress(
        currentStep: '',
        stepKey: BuildStepKey.initializing,
      ),
    );

    _buildSubscription?.cancel();
    _buildSubscription = stream.listen(
      (progress) {
        state = state.copyWith(progress: progress);
      },
      onDone: () {
        final currentProgress = state.progress;
        final hasError =
            currentProgress?.error != null || currentProgress?.errorKey != null;
        state = state.copyWith(
          status: hasError ? BuildStatus.error : BuildStatus.completed,
        );
        refreshColabStatus();
      },
      onError: (error) {
        state = state.copyWith(
          status: BuildStatus.error,
          progress: state.progress?.copyWith(
            error: error.toString(),
            isComplete: true,
          ),
        );
      },
    );
  }

  void reset() {
    _buildSubscription?.cancel();
    _builderService.cancel();
    state = state.copyWith(status: BuildStatus.idle, clearProgress: true);
  }

  void _dispose() {
    _buildSubscription?.cancel();
    _builderService.cancel();
    _modelDownloader?.cancel();
  }
}

/// Provider for HomeViewModel
final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  () => HomeViewModel(
    getIt<MpqBuilderService>(),
    getIt<SettingsService>(),
    getIt<SuperResolutionService>(),
  ),
);
