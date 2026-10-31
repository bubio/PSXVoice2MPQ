import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:psxvoice2mpq/main.dart' as app;
import 'package:psxvoice2mpq/viewmodels/home_viewmodel.dart';
import 'package:psxvoice2mpq/views/home_view.dart';
import 'package:psxvoice2mpq/widgets/folder_selector.dart';

import '../test/support/synthetic_stream.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory inputDir;
  late Directory outputDir;

  setUp(() async {
    inputDir = await Directory.systemTemp.createTemp('psx_e2e_in_');
    outputDir = await Directory.systemTemp.createTemp('psx_e2e_out_');
    await writeSyntheticStream(inputDir);
  });

  tearDown(() async {
    await inputDir.delete(recursive: true);
    await outputDir.delete(recursive: true);
  });

  testWidgets('entering folders and pressing Build writes en.mpq', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    final pathFields = find.descendant(
      of: find.byType(FolderSelector),
      matching: find.byType(TextField),
    );
    await tester.enterText(pathFields.at(0), inputDir.path);
    await tester.enterText(pathFields.at(1), outputDir.path);
    await tester.pump();

    await tester.tap(find.byKey(const Key('buildButton')));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeView)),
    );
    final deadline = DateTime.now().add(const Duration(minutes: 1));
    while (container.read(homeViewModelProvider).status ==
        BuildStatus.building) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Build did not finish within 1 minute');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    final state = container.read(homeViewModelProvider);
    expect(
      state.status,
      BuildStatus.completed,
      reason: state.progress?.logs.join('\n'),
    );

    // Real StormLib from the app bundle wrote an MPQ archive
    final mpq = File(p.join(outputDir.path, 'en.mpq'));
    expect(await mpq.exists(), isTrue);
    final header = (await mpq.readAsBytes()).sublist(0, 4);
    expect(header, [0x4D, 0x50, 0x51, 0x1A]); // 'MPQ\x1A'
  });
}
