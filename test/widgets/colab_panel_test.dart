import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/l10n/app_localizations.dart';
import 'package:psxvoice2mpq/services/super_resolution/colab_exchange.dart';
import 'package:psxvoice2mpq/widgets/colab_panel.dart';

ColabInputStatus _input(int total, int imported) => ColabInputStatus(
  path: '/out/sr_input.zip',
  modified: DateTime(2026),
  total: total,
  imported: imported,
);

void main() {
  late List<String> calls;

  Future<void> pump(
    WidgetTester tester, {
    ColabInputStatus? input,
    String? result,
    bool enabled = true,
  }) async {
    calls = [];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ColabPanel(
            input: input,
            resultPath: result,
            enabled: enabled,
            onExport: () => calls.add('export'),
            onOpenFolder: () => calls.add('folder'),
            onOpenColab: () => calls.add('colab'),
            onImportAndBuild: () => calls.add('importAndBuild'),
            onChooseFile: () => calls.add('choose'),
            onBuild: () => calls.add('build'),
          ),
        ),
      ),
    );
  }

  /// The step whose title is bold is the one to do next.
  int currentStep(WidgetTester tester) {
    for (final n in [1, 2, 3]) {
      final title = tester.widget<Text>(find.textContaining(RegExp('^$n\\. ')));
      if (title.style?.fontWeight == FontWeight.bold) return n;
    }
    return 0;
  }

  bool isEnabled(WidgetTester tester, String key) =>
      tester
          .widget<ButtonStyleButton>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          )
          .onPressed !=
      null;

  testWidgets('before exporting, only export is possible', (tester) async {
    await pump(tester);
    expect(currentStep(tester), 1);
    expect(isEnabled(tester, 'openColabButton'), isFalse);
    expect(isEnabled(tester, 'colabChooseFileButton'), isFalse);
    expect(find.text('Writes sr_input.zip to the output folder.'), findsOne);

    await tester.tap(find.byKey(const Key('colabExportButton')));
    expect(calls, ['export']);
  });

  testWidgets('after exporting, Colab is next', (tester) async {
    await pump(tester, input: _input(732, 0));
    expect(currentStep(tester), 2);
    expect(find.text('Exported 732 voices: sr_input.zip'), findsOne);
    expect(find.text('0 of 732 voices imported'), findsOne);

    await tester.tap(find.byKey(const Key('openColabButton')));
    await tester.tap(find.byKey(const Key('colabChooseFileButton')));
    await tester.tap(find.textContaining('Build without importing'));
    expect(calls, ['colab', 'choose', 'build']);
  });

  testWidgets('a downloaded result is offered for import', (tester) async {
    await pump(
      tester,
      input: _input(732, 0),
      result: '/home/me/Downloads/sr_output.zip',
    );
    expect(currentStep(tester), 3);
    expect(find.text('Found: /home/me/Downloads/sr_output.zip'), findsOne);

    await tester.tap(find.byKey(const Key('colabImportBuildButton')));
    expect(calls, ['importAndBuild']);
  });

  testWidgets('when everything is imported, step 3 just builds', (
    tester,
  ) async {
    await pump(tester, input: _input(732, 732));
    expect(currentStep(tester), 3);
    expect(find.textContaining('Build without importing'), findsNothing);

    await tester.tap(find.byKey(const Key('colabBuildButton')));
    expect(calls, ['build']);
  });

  testWidgets('nothing to convert skips straight to building', (tester) async {
    await pump(tester, input: _input(0, 0));
    expect(currentStep(tester), 3);
    expect(
      find.text('All voices are already enhanced. Build in step 3.'),
      findsOne,
    );
    expect(find.byKey(const Key('colabBuildButton')), findsOne);
  });

  testWidgets('buttons are disabled while building', (tester) async {
    await pump(tester, input: _input(732, 0), enabled: false);
    expect(isEnabled(tester, 'colabExportButton'), isFalse);
    expect(isEnabled(tester, 'colabChooseFileButton'), isFalse);
  });
}
