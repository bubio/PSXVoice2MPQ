import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/core/di/service_locator.dart';
import 'package:psxvoice2mpq/main.dart' as app;
import 'package:psxvoice2mpq/services/super_resolution/super_resolution_service.dart';
import 'package:psxvoice2mpq/services/super_resolution/wav_io.dart';
import 'package:psxvoice2mpq/viewmodels/home_viewmodel.dart';
import 'package:psxvoice2mpq/views/home_view.dart';
import 'package:psxvoice2mpq/widgets/folder_selector.dart';

import '../test/support/synthetic_stream.dart';

/// Downloads the real model (about 430 MB) from the GitHub release into the
/// app's data directory, so it only runs when asked for:
///
///   flutter test integration_test/super_resolution_flow_test.dart \
///     -d macos --dart-define=SR_E2E=true
const _enabled = bool.fromEnvironment('SR_E2E');

/// Optional directory for screenshots of the settings dialog (macOS only).
const _screenshotDir = String.fromEnvironment('SR_E2E_SCREENSHOTS');

Future<void> _screenshot(WidgetTester tester, String name) async {
  if (_screenshotDir.isEmpty || !Platform.isMacOS) return;
  await tester.pump();
  await Process.run('screencapture', [
    '-x',
    p.join(_screenshotDir, '$name.png'),
  ]);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done,
  Duration timeout,
  String what,
) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('$what timed out');
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory inputDir;
  late Directory outputDir;

  setUp(() async {
    inputDir = await Directory.systemTemp.createTemp('psx_sr_in_');
    outputDir = await Directory.systemTemp.createTemp('psx_sr_out_');
    await writeSyntheticStream(inputDir);
  });

  tearDown(() async {
    await inputDir.delete(recursive: true);
    await outputDir.delete(recursive: true);
  });

  testWidgets(
    'download the model from settings, enable it and build at 44.1kHz',
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 40)),
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeView)),
      );
      HomeState state() => container.read(homeViewModelProvider);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await _screenshot(tester, '1_settings');

      if (!state().superResolutionAvailable) {
        await tester.tap(find.byIcon(Icons.download));
        await _pumpUntil(
          tester,
          () => (state().modelDownloadProgress ?? 0) > 0.05,
          const Duration(minutes: 5),
          'Download start',
        );
        await _screenshot(tester, '2_downloading');
        await _pumpUntil(
          tester,
          () =>
              state().superResolutionAvailable ||
              state().modelDownloadError != null,
          const Duration(minutes: 30),
          'Download',
        );
        expect(state().modelDownloadError, isNull);
      }
      await tester.pumpAndSettle();
      await _screenshot(tester, '3_installed');

      if (!state().superResolutionActive) {
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
      }
      expect(state().superResolutionActive, isTrue);
      await _screenshot(tester, '4_enabled');
      final close = MaterialLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      ).closeButtonLabel;
      await tester.tap(find.widgetWithText(TextButton, close));
      await tester.pumpAndSettle();

      // Start from an empty cache so the files below come from this build.
      final cache = Directory(getIt<SuperResolutionService>().cacheDir);
      if (cache.existsSync()) cache.deleteSync(recursive: true);

      final pathFields = find.descendant(
        of: find.byType(FolderSelector),
        matching: find.byType(TextField),
      );
      await tester.enterText(pathFields.at(0), inputDir.path);
      await tester.enterText(pathFields.at(1), outputDir.path);
      await tester.pump();
      await tester.tap(find.byKey(const Key('buildButton')));
      await tester.pump();
      await _pumpUntil(
        tester,
        () => state().status != BuildStatus.building,
        const Duration(minutes: 5),
        'Build',
      );
      expect(
        state().status,
        BuildStatus.completed,
        reason: state().progress?.logs.join('\n'),
      );
      expect(File(p.join(outputDir.path, 'en.mpq')).existsSync(), isTrue);

      // The synthetic voices share one payload, so the cache keyed by input
      // hash holds a single enhanced file for all of them.
      final enhanced = cache
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .toList();
      expect(enhanced, isNotEmpty);
      for (final f in enhanced) {
        expect(decodePcm16Mono(f.readAsBytesSync())!.sampleRate, 44100);
      }
    },
  );
}
