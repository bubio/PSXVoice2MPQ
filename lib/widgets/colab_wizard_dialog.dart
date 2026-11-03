import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import '../viewmodels/home_viewmodel.dart';

/// Walks the user through super-resolution on Google Colab one step per
/// page: export `sr_input.zip`, run the notebook in the browser, then import
/// `sr_output.zip` and build.
///
/// Colab cannot be driven from the app, so the middle step is instructions
/// for the browser. The dialog opens at the first unfinished step and pops
/// with the number of imported voices when it starts the build.
class ColabWizardDialog extends ConsumerStatefulWidget {
  final VoidCallback onOpenColab;
  final ValueChanged<String> onOpenFolder;

  /// Lets the user choose a result zip; null if cancelled.
  final Future<String?> Function() pickResultZip;

  const ColabWizardDialog({
    super.key,
    required this.onOpenColab,
    required this.onOpenFolder,
    required this.pickResultZip,
  });

  @override
  ConsumerState<ColabWizardDialog> createState() => _ColabWizardDialogState();
}

class _ColabWizardDialogState extends ConsumerState<ColabWizardDialog> {
  late int _page;
  bool _exporting = false;
  bool _importing = false;
  String? _pickedResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = ref.read(homeViewModelProvider);
    final input = state.colabInput;
    _page = input == null
        ? 0
        : (input.complete || state.colabResultPath != null)
        ? 2
        : 1;
  }

  HomeViewModel get _notifier => ref.read(homeViewModelProvider.notifier);

  void _export() {
    setState(() => _exporting = true);
    _notifier.exportForColab();
  }

  Future<void> _chooseResult() async {
    final path = await widget.pickResultZip();
    if (path != null) setState(() => _pickedResult = path);
  }

  Future<void> _importAndBuild(String path) async {
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      final count = await _notifier.importColabResultAndBuild(path);
      if (mounted) Navigator.of(context).pop(count);
    } catch (e) {
      if (mounted) {
        setState(() {
          _importing = false;
          _error = AppLocalizations.of(context)!.colabImportFailed('$e');
        });
      }
    }
  }

  void _build() {
    Navigator.of(context).pop();
    _notifier.startBuild();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final state = ref.watch(homeViewModelProvider);
    final input = state.colabInput;
    final exporting = _exporting && state.isBuilding;
    final result = _pickedResult ?? state.colabResultPath;

    final Widget content;
    final Widget primary;
    switch (_page) {
      case 0:
        content = _exportPage(l10n, state, exporting);
        primary = FilledButton(
          key: const Key('colabNextButton'),
          onPressed: input != null && !exporting
              ? () => setState(() => _page = input.total == 0 ? 2 : 1)
              : null,
          child: Text(l10n.wizardNext),
        );
      case 1:
        content = _colabPage(l10n, state);
        primary = FilledButton(
          key: const Key('colabNextButton'),
          onPressed: () => setState(() => _page = 2),
          child: Text(l10n.wizardNext),
        );
      default:
        content = _importPage(l10n, state, result);
        final complete = input?.complete ?? false;
        primary = result != null || !complete
            ? FilledButton.icon(
                key: const Key('colabImportBuildButton'),
                onPressed: result == null || _importing
                    ? null
                    : () => _importAndBuild(result),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.importAndBuild),
              )
            : FilledButton.icon(
                key: const Key('colabBuildButton'),
                onPressed: _build,
                icon: const Icon(Icons.build, size: 18),
                label: Text(l10n.buildMpq),
              );
    }

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.colabWizardTitle),
          const SizedBox(height: 4),
          Text(
            l10n.colabStepOf(_page + 1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(child: content),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(materialL10n.closeButtonLabel),
        ),
        if (_page > 0)
          OutlinedButton(
            key: const Key('colabBackButton'),
            onPressed: exporting || _importing
                ? null
                : () => setState(() => _page--),
            child: Text(l10n.wizardBack),
          ),
        primary,
      ],
    );
  }

  Widget _exportPage(AppLocalizations l10n, HomeState state, bool exporting) {
    final input = state.colabInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '1. ${l10n.colabStep1Title}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.colabStep1Explain),
        const SizedBox(height: 16),
        if (exporting) ...[
          Text(l10n.colabExporting),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: state.progress?.percentage),
        ] else if (input != null) ...[
          _Done(
            input.total == 0
                ? l10n.colabStep1Nothing
                : l10n.colabStep1Done(input.total, p.basename(input.path)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => widget.onOpenFolder(p.dirname(input.path)),
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(l10n.openFolder),
              ),
              TextButton(
                key: const Key('colabExportButton'),
                onPressed: state.isBuilding ? null : _export,
                child: Text(l10n.colabReexport),
              ),
            ],
          ),
        ] else
          Center(
            child: FilledButton.icon(
              key: const Key('colabExportButton'),
              onPressed: state.isBuilding ? null : _export,
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(l10n.colabExport),
            ),
          ),
      ],
    );
  }

  Widget _colabPage(AppLocalizations l10n, HomeState state) {
    final input = state.colabInput;
    final steps = [
      l10n.colabStep2Open,
      l10n.colabStep2Run,
      l10n.colabStep2Upload,
      l10n.colabStep2Wait,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '2. ${l10n.colabStep2Title}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final (i, text) in steps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 24, child: Text('${i + 1}.')),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('openColabButton'),
              onPressed: widget.onOpenColab,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.openColab),
            ),
            if (input != null)
              OutlinedButton.icon(
                onPressed: () => widget.onOpenFolder(p.dirname(input.path)),
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(l10n.openFolder),
              ),
          ],
        ),
        if (state.colabResultPath != null) ...[
          const SizedBox(height: 16),
          _Done(l10n.colabStep2Arrived),
        ],
      ],
    );
  }

  Widget _importPage(AppLocalizations l10n, HomeState state, String? result) {
    final input = state.colabInput;
    final complete = input?.complete ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '3. ${l10n.colabStep3Title}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.colabStep3Explain),
        const SizedBox(height: 16),
        if (input != null && input.total > 0)
          Text(l10n.colabStep3Imported(input.imported, input.total)),
        const SizedBox(height: 8),
        if (result != null)
          _Done(l10n.colabStep3Found(p.normalize(result)))
        else if (!complete)
          Text(l10n.colabStep3NotFound),
        if (!complete || result != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('colabChooseFileButton'),
            onPressed: _importing ? null : _chooseResult,
            icon: const Icon(Icons.folder_open, size: 18),
            label: Text(
              result == null ? l10n.chooseFile : l10n.chooseOtherFile,
            ),
          ),
        ],
        if (_importing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _Done extends StatelessWidget {
  final String text;

  const _Done(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 20, color: Colors.green.shade400),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
