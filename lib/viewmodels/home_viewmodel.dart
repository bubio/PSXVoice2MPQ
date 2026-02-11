import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/path_constants.dart';
import '../core/di/service_locator.dart';
import '../models/build_progress.dart';
import '../services/mpq_builder_service.dart';
import '../services/process_runner.dart';
import '../services/settings_service.dart';

/// Build status enum
enum BuildStatus { idle, building, completed, error }

/// Home screen state
class HomeState {
  final String assetsPath;
  final String outputPath;
  final BuildStatus status;
  final BuildProgress? progress;
  final Locale? locale;
  final bool useAudioSr;
  final bool audioSrAvailable;
  final String? audioSrPath;
  final bool audioSrUseCpu;
  final int audioSrChunkSeconds;

  const HomeState({
    required this.assetsPath,
    required this.outputPath,
    required this.status,
    this.progress,
    this.locale,
    this.useAudioSr = false,
    this.audioSrAvailable = false,
    this.audioSrPath,
    this.audioSrUseCpu = false,
    this.audioSrChunkSeconds = 5,
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

  HomeState copyWith({
    String? assetsPath,
    String? outputPath,
    BuildStatus? status,
    BuildProgress? progress,
    Locale? locale,
    bool? useAudioSr,
    bool? audioSrAvailable,
    String? audioSrPath,
    bool? audioSrUseCpu,
    int? audioSrChunkSeconds,
    bool clearProgress = false,
    bool clearAudioSrPath = false,
  }) {
    return HomeState(
      assetsPath: assetsPath ?? this.assetsPath,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      progress: clearProgress ? null : (progress ?? this.progress),
      locale: locale ?? this.locale,
      useAudioSr: useAudioSr ?? this.useAudioSr,
      audioSrAvailable: audioSrAvailable ?? this.audioSrAvailable,
      audioSrPath: clearAudioSrPath ? null : (audioSrPath ?? this.audioSrPath),
      audioSrUseCpu: audioSrUseCpu ?? this.audioSrUseCpu,
      audioSrChunkSeconds: audioSrChunkSeconds ?? this.audioSrChunkSeconds,
    );
  }
}

/// HomeViewModel using Riverpod StateNotifier
class HomeViewModel extends StateNotifier<HomeState> {
  final MpqBuilderService _builderService;
  final ProcessRunner _processRunner;
  final SettingsService _settingsService;
  StreamSubscription<BuildProgress>? _buildSubscription;

  HomeViewModel(
    this._builderService,
    this._processRunner,
    this._settingsService,
  ) : super(HomeState.initial()) {
    if (AppConstants.enableAudioSr) {
      _initAudioSr();
    }
  }

  Future<void> _initAudioSr() async {
    // Load AudioSR CPU and chunk settings
    final useCpu = await _settingsService.getAudioSrUseCpu();
    final chunkSeconds = await _settingsService.getAudioSrChunkSeconds();
    state = state.copyWith(
      audioSrUseCpu: useCpu,
      audioSrChunkSeconds: chunkSeconds,
    );

    // Load saved path from settings
    final savedPath = await _settingsService.getAudioSrPath();
    if (savedPath != null && await _processRunner.isValidAudioSr(savedPath)) {
      state = state.copyWith(
        audioSrPath: savedPath,
        audioSrAvailable: true,
        useAudioSr: true,
      );
      return;
    }

    // Try auto-detection via PATH
    await checkAudioSrAvailability();
  }

  Future<void> checkAudioSrAvailability() async {
    final path = await _processRunner.findAudioSr();
    if (path != null) {
      state = state.copyWith(
        audioSrPath: path,
        audioSrAvailable: true,
        useAudioSr: true,
      );
    } else {
      state = state.copyWith(
        audioSrAvailable: false,
        useAudioSr: false,
        clearAudioSrPath: true,
      );
    }
  }

  void setUseAudioSr(bool value) {
    if (!state.audioSrAvailable) return;
    state = state.copyWith(useAudioSr: value);
  }

  Future<void> setAudioSrUseCpu(bool value) async {
    state = state.copyWith(audioSrUseCpu: value);
    await _settingsService.setAudioSrUseCpu(value);
  }

  Future<void> setAudioSrChunkSeconds(int value) async {
    state = state.copyWith(audioSrChunkSeconds: value);
    await _settingsService.setAudioSrChunkSeconds(value);
  }

  Future<void> setAudioSrPath(String? path) async {
    if (path != null && await _processRunner.isValidAudioSr(path)) {
      await _settingsService.setAudioSrPath(path);
      state = state.copyWith(
        audioSrPath: path,
        audioSrAvailable: true,
        useAudioSr: true,
      );
    } else {
      await _settingsService.setAudioSrPath(null);
      // Re-check auto-detection
      await checkAudioSrAvailability();
    }
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

    final audioSrPath =
        AppConstants.enableAudioSr && state.useAudioSr
            ? state.audioSrPath
            : null;

    _buildSubscription?.cancel();
    _buildSubscription = _builderService
        .build(
          state.assetsPath,
          state.outputPath,
          audioSrPath: audioSrPath,
          audioSrUseCpu: state.audioSrUseCpu,
          audioSrChunkSeconds: state.audioSrChunkSeconds,
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

  @override
  void dispose() {
    _buildSubscription?.cancel();
    _builderService.cancel();
    super.dispose();
  }
}

/// Provider for HomeViewModel
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel(
    getIt<MpqBuilderService>(),
    getIt<ProcessRunner>(),
    getIt<SettingsService>(),
  );
});
