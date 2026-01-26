import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/path_constants.dart';
import '../core/di/service_locator.dart';
import '../models/build_progress.dart';
import '../models/build_state.dart';
import '../services/mpq_builder_service.dart';

/// Build status enum
enum BuildStatus { idle, building, completed, error }

/// Home screen state
class HomeState {
  final String assetsPath;
  final String outputPath;
  final BuildStatus status;
  final BuildProgress? progress;
  final Locale? locale;

  const HomeState({
    required this.assetsPath,
    required this.outputPath,
    required this.status,
    this.progress,
    this.locale,
  });

  factory HomeState.initial() {
    return HomeState(
      assetsPath: kDebugMode ? '/Users/seiji/dev/psx-tools/ps1_assets' : '',
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
    bool clearProgress = false,
  }) {
    return HomeState(
      assetsPath: assetsPath ?? this.assetsPath,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      progress: clearProgress ? null : (progress ?? this.progress),
      locale: locale ?? this.locale,
    );
  }
}

/// HomeViewModel using Riverpod StateNotifier
class HomeViewModel extends StateNotifier<HomeState> {
  final MpqBuilderService _builderService;
  StreamSubscription<BuildProgress>? _buildSubscription;

  HomeViewModel(this._builderService) : super(HomeState.initial());

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
        .build(state.assetsPath, state.outputPath)
        .listen(
          (progress) {
            state = state.copyWith(progress: progress);
          },
          onDone: () {
            final currentProgress = state.progress;
            final hasError = currentProgress?.error != null ||
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
    state = state.copyWith(
      status: BuildStatus.idle,
      clearProgress: true,
    );
  }

  @override
  void dispose() {
    _buildSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for HomeViewModel
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(getIt<MpqBuilderService>());
});
