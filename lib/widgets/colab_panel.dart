import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import '../services/super_resolution/colab_exchange.dart';

/// The three steps of super-resolution on Google Colab, shown on the main
/// screen in place of the build button: export, convert in the notebook,
/// then import the result and build.
///
/// Each step shows whether it is done and what to do next, based on the
/// exported `sr_input.zip` ([input]) and a result zip found in the Downloads
/// or output folder ([resultPath]).
class ColabPanel extends StatelessWidget {
  final ColabInputStatus? input;
  final String? resultPath;

  /// False while a build or export runs, or before both folders are set.
  final bool enabled;

  final VoidCallback onExport;
  final VoidCallback onOpenFolder;
  final VoidCallback onOpenColab;

  /// Imports [resultPath] and builds.
  final VoidCallback onImportAndBuild;

  /// Lets the user pick a result zip, then imports it and builds.
  final VoidCallback onChooseFile;

  /// Builds with the results imported so far.
  final VoidCallback onBuild;

  const ColabPanel({
    super.key,
    required this.input,
    required this.resultPath,
    required this.enabled,
    required this.onExport,
    required this.onOpenFolder,
    required this.onOpenColab,
    required this.onImportAndBuild,
    required this.onChooseFile,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final input = this.input;
    final resultPath = this.resultPath;

    final exported = input != null;
    final converted = resultPath != null || (input?.complete ?? false);
    final current = !exported ? 1 : (!converted ? 2 : 3);
    final allImported = input?.complete ?? false;

    VoidCallback? when(bool ok, VoidCallback f) => enabled && ok ? f : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.colabPanelTitle, style: theme.textTheme.titleSmall),
          _Step(
            number: 1,
            current: current,
            done: exported,
            title: l10n.colabStep1Title,
            details: [
              if (input == null)
                Text(l10n.colabStep1Hint)
              else
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        input.total == 0
                            ? l10n.colabStep1Nothing
                            : l10n.colabStep1Done(
                                input.total,
                                p.basename(input.path),
                              ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Link(l10n.openFolder, enabled ? onOpenFolder : null),
                  ],
                ),
            ],
            action: _Action(
              key: const Key('colabExportButton'),
              label: l10n.colabExport,
              icon: Icons.upload_file,
              primary: current == 1,
              onPressed: when(true, onExport),
            ),
          ),
          _Step(
            number: 2,
            current: current,
            done: converted,
            title: l10n.colabStep2Title,
            details: [if (current == 2) Text(l10n.colabStep2Hint)],
            action: _Action(
              key: const Key('openColabButton'),
              label: l10n.openColab,
              icon: Icons.open_in_new,
              primary: current == 2,
              onPressed: exported ? onOpenColab : null,
            ),
          ),
          _Step(
            number: 3,
            current: current,
            done: false,
            title: l10n.colabStep3Title,
            details: [
              if (input != null && input.total > 0)
                Text(l10n.colabStep3Imported(input.imported, input.total)),
              if (resultPath != null)
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.colabStep3Found(p.normalize(resultPath)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Link(l10n.chooseOtherFile, when(true, onChooseFile)),
                  ],
                )
              else if (current == 3 && !allImported)
                Text(l10n.colabStep3Hint),
              if (!allImported && exported)
                _Link(l10n.buildWithoutImport, when(true, onBuild)),
            ],
            action: resultPath != null
                ? _Action(
                    key: const Key('colabImportBuildButton'),
                    label: l10n.importAndBuild,
                    icon: Icons.download,
                    primary: current == 3,
                    onPressed: when(true, onImportAndBuild),
                  )
                : allImported
                ? _Action(
                    key: const Key('colabBuildButton'),
                    label: l10n.buildMpq,
                    icon: Icons.build,
                    primary: current == 3,
                    onPressed: when(true, onBuild),
                  )
                : _Action(
                    key: const Key('colabChooseFileButton'),
                    label: l10n.chooseFile,
                    icon: Icons.folder_open,
                    primary: false,
                    onPressed: when(exported, onChooseFile),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final int current;
  final bool done;
  final String title;
  final List<Widget> details;
  final Widget action;

  const _Step({
    required this.number,
    required this.current,
    required this.done,
    required this.title,
    required this.details,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = number == current;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final icon = done && !active
        ? Icon(Icons.check_circle, size: 20, color: Colors.green.shade400)
        : active
        ? Icon(Icons.play_circle, size: 20, color: theme.colorScheme.primary)
        : Icon(Icons.circle_outlined, size: 20, color: muted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: icon),
          const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 12, color: muted),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: active ? FontWeight.bold : null,
                      color: active ? null : muted,
                    ),
                  ),
                  ...details,
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onPressed;

  const _Action({
    super.key,
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    return primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: child,
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: child,
          );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _Link(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
