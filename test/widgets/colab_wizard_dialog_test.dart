import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psxvoice2mpq/core/di/service_locator.dart';
import 'package:psxvoice2mpq/l10n/app_localizations.dart';
import 'package:psxvoice2mpq/services/mpq_builder_service.dart';
import 'package:psxvoice2mpq/services/settings_service.dart';
import 'package:psxvoice2mpq/services/super_resolution/colab_exchange.dart';
import 'package:psxvoice2mpq/services/super_resolution/super_resolution_service.dart';
import 'package:psxvoice2mpq/viewmodels/home_viewmodel.dart';
import 'package:psxvoice2mpq/widgets/colab_wizard_dialog.dart';

/// Records what the dialog asks the view model to do.
class _FakeViewModel extends HomeViewModel {
  final HomeState initial;
  final List<String> calls;

  _FakeViewModel(this.initial, this.calls)
    : super(
        getIt<MpqBuilderService>(),
        getIt<SettingsService>(),
        getIt<SuperResolutionService>(),
      );

  @override
  HomeState build() => initial;

  void set(HomeState value) => state = value;

  @override
  Future<void> exportForColab() async => calls.add('export');

  @override
  Future<int> importColabResultAndBuild(String zipPath) async {
    calls.add('import $zipPath');
    return 3;
  }

  @override
  Future<void> startBuild() async => calls.add('build');
}

ColabInputStatus _input(int total, int imported) => ColabInputStatus(
  path: '/out/sr_input.zip',
  modified: DateTime(2026),
  total: total,
  imported: imported,
);

HomeState _state({ColabInputStatus? input, String? result}) => HomeState(
  assetsPath: '/in',
  outputPath: '/out',
  status: BuildStatus.idle,
  useSuperResolution: true,
  superResolutionOnColab: true,
  colabInput: input,
  colabResultPath: result,
);

void main() {
  setUpAll(setupServiceLocator);

  late List<String> calls;
  late _FakeViewModel viewModel;
  Object? popped;

  Future<void> open(
    WidgetTester tester,
    HomeState state, {
    String? picked,
  }) async {
    calls = [];
    popped = null;
    viewModel = _FakeViewModel(state, calls);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWith(() => viewModel)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                popped = await showDialog<Object>(
                  context: context,
                  builder: (_) => ColabWizardDialog(
                    onOpenColab: () => calls.add('colab'),
                    onOpenFolder: (dir) => calls.add('folder $dir'),
                    pickResultZip: () async => picked,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed != null;

  testWidgets('walks from export to import and build', (tester) async {
    await open(tester, _state());
    expect(find.text('Step 1 of 3'), findsOne);
    expect(enabled(tester, 'colabNextButton'), isFalse);

    await tester.tap(find.byKey(const Key('colabExportButton')));
    viewModel.set(_state(input: _input(732, 0)));
    await tester.pumpAndSettle();
    expect(find.text('Exported 732 voices: sr_input.zip'), findsOne);

    await tester.tap(find.byKey(const Key('colabNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOne);
    await tester.tap(find.byKey(const Key('openColabButton')));

    // The result shows up when the user comes back from the browser.
    viewModel.set(_state(input: _input(732, 0), result: '/dl/sr_output.zip'));
    await tester.pumpAndSettle();
    expect(
      find.text('sr_output.zip has been downloaded. Press Next.'),
      findsOne,
    );

    await tester.tap(find.byKey(const Key('colabNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOne);
    expect(find.text('Found: /dl/sr_output.zip'), findsOne);

    await tester.tap(find.byKey(const Key('colabImportBuildButton')));
    await tester.pumpAndSettle();
    expect(calls, ['export', 'colab', 'import /dl/sr_output.zip']);
    expect(popped, 3);
  });

  testWidgets('opens at the step that is not done yet', (tester) async {
    await open(tester, _state(input: _input(732, 0)));
    expect(find.text('Step 2 of 3'), findsOne);

    await tester.tap(find.byKey(const Key('colabBackButton')));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOne);
  });

  testWidgets('without a downloaded result, the user picks the file', (
    tester,
  ) async {
    await open(tester, _state(input: _input(732, 0)), picked: '/x/out.zip');
    await tester.tap(find.byKey(const Key('colabNextButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('sr_output.zip was not found'), findsOne);
    expect(enabled(tester, 'colabImportBuildButton'), isFalse);

    await tester.tap(find.byKey(const Key('colabChooseFileButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('colabImportBuildButton')));
    await tester.pumpAndSettle();
    expect(calls, ['import /x/out.zip']);
  });

  testWidgets('when everything is imported, it just builds', (tester) async {
    await open(tester, _state(input: _input(732, 732)));
    expect(find.text('Step 3 of 3'), findsOne);

    await tester.tap(find.byKey(const Key('colabBuildButton')));
    await tester.pumpAndSettle();
    expect(calls, ['build']);
  });

  testWidgets('nothing to convert skips the Colab step', (tester) async {
    await open(tester, _state());
    viewModel.set(_state(input: _input(0, 0)));
    await tester.pumpAndSettle();
    expect(
      find.text('All voices are already enhanced. Build in step 3.'),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('colabNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOne);
  });
}
