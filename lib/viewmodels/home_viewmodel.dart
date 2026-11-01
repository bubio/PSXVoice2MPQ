import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/path_constants.dart';
import '../core/di/service_locator.dart';
import '../models/build_progress.dart';
import '../services/mpq_builder_service.dart';
import '../services/settings_service.dart';
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

  /// Download progress (0..1) of the model, or null when not downloading.
  final double? modelDownloadProgress;

  /// Error from the last model download, if it failed.
  final String? modelDownloadError;

  const HomeState({
    required this.assetsPath,
    required this.outputPath,
    required this.status,
    this.progress,
    this.locale,
    this.useSuperResolution = false,
    this.superResolutionAvailable = false,
    this.modelDownloadProgress,
    this.modelDownloadError,
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
      useSuperResolution && superResolutionAvailable;

  HomeState copyWith({
    String? assetsPath,
    String? outputPath,
    BuildStatus? status,
    BuildProgress? progress,
    Locale? locale,
    bool? useSuperResolution,
    bool? superResolutionAvailable,
    double? modelDownloadProgress,
    String? modelDownloadError,
    bool clearProgress = false,
    bool clearModelDownload = false,
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
      modelDownloadProgress: clearModelDownload
          ? null
          : (modelDownloadProgress ?? this.modelDownloadProgress),
      modelDownloadError: clearModelDownload
          ? null
          : (modelDownloadError ?? this.modelDownloadError),
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
    state = state.copyWith(
      useSuperResolution: enabled,
      superResolutionAvailable: _superResolution.isModelInstalled,
    );
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

  void setAssetsPath(String path) {
    state = state.copyWith(assetsPath: path);
  }

  void setOutputPath(String path) {
    state = state.copyWith(outputPath: path);
  }

  void setLocale(Locale? locale) {
    state = state.copyWith(locale: locale);
  }

  Future<void> startBuild() async {
    if (!state.canBuild) return;

    state = state.copyWith(
      status: BuildStatus.building,
      progress: BuildProgress(
        currentStep: '',
        stepKey: BuildStepKey.initializing,
      ),
    );

    _buildSubscription?.cancel();
    _buildSubscription = _builderService
        .build(
          state.assetsPath,
          state.outputPath,
          superResolution: state.superResolutionActive,
        )
        .listen(
          (progress) {
            state = state.copyWith(progress: progress);
          },
          onDone: () {
            final currentProgress = state.progress;
            final hasError =
                currentProgress?.error != null ||
                currentProgress?.errorKey != null;
            state = state.copyWith(
              status: hasError ? BuildStatus.error : BuildStatus.completed,
            );
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
