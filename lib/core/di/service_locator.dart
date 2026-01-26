import 'package:get_it/get_it.dart';

import '../../services/mpq_builder_service.dart';
import '../../services/process_runner.dart';

final getIt = GetIt.instance;

/// Initialize the service locator with all dependencies
void setupServiceLocator() {
  // Register services as lazy singletons
  getIt.registerLazySingleton<ProcessRunner>(() => ProcessRunner());

  getIt.registerLazySingleton<MpqBuilderService>(
    () => MpqBuilderService(
      processRunner: getIt<ProcessRunner>(),
    ),
  );
}
