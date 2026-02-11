import 'package:get_it/get_it.dart';

import '../../services/mpq_builder_service.dart';
import '../../services/process_runner.dart';
import '../../services/settings_service.dart';
import '../../services/stormlib_service.dart';

final getIt = GetIt.instance;

/// Initialize the service locator with all dependencies
void setupServiceLocator() {
  // Register services as lazy singletons
  getIt.registerLazySingleton<ProcessRunner>(() => ProcessRunner());

  getIt.registerLazySingleton<StormLibService>(() => StormLibService());

  getIt.registerLazySingleton<SettingsService>(() => SettingsService());

  getIt.registerLazySingleton<MpqBuilderService>(
    () => MpqBuilderService(
      processRunner: getIt<ProcessRunner>(),
      stormLibService: getIt<StormLibService>(),
    ),
  );
}
