import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/path_constants.dart';
import '../core/constants/stream_constants.dart';
import '../l10n/app_localizations.dart';
import '../services/super_resolution/model_downloader.dart';
import '../viewmodels/home_viewmodel.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  final String currentLocaleKey;
  final ValueChanged<String> onLocaleChanged;

  const SettingsDialog({
    super.key,
    required this.currentLocaleKey,
    required this.onLocaleChanged,
  });

  static String getLocaleKey(Locale? locale) {
    if (locale == null) return 'system';
    if (locale.countryCode != null) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  static Locale? parseLocaleKey(String key) {
    if (key == 'system') return null;
    final parts = key.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late String _selectedLocaleKey;
  PackageInfo? _packageInfo;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedLocaleKey = widget.currentLocaleKey;
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(homeViewModelProvider);

    return AlertDialog(
      title: Text(l10n.settings),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrollable content
            Flexible(
              child: Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.hardEdge,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.superResolutionSection,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.enableSuperResolution),
                          subtitle: Text(
                            state.superResolutionAvailable
                                ? l10n.superResolutionNote
                                : l10n.superResolutionModelMissing,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: state.superResolutionAvailable
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.error,
                            ),
                          ),
                          value: state.superResolutionActive,
                          onChanged: state.superResolutionAvailable
                              ? (value) {
                                  ref
                                      .read(homeViewModelProvider.notifier)
                                      .setUseSuperResolution(value ?? false);
                                }
                              : null,
                        ),
                        if (!state.superResolutionAvailable)
                          _ModelDownloadControls(state: state),
                        // Cache section
                        TextButton.icon(
                          onPressed: () async {
                            final cacheDir = Directory(
                              PathConstants.getCacheDir(),
                            );
                            if (await cacheDir.exists()) {
                              await cacheDir.delete(recursive: true);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.cacheCleared)),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.clearCache),
                        ),
                        // Language section
                        const Divider(height: 24),
                        Text(l10n.language, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _selectedLocaleKey,
                          isExpanded: true,
                          onChanged: (key) {
                            if (key != null) {
                              setState(() {
                                _selectedLocaleKey = key;
                              });
                              widget.onLocaleChanged(key);
                            }
                          },
                          items: StreamConstants.languageDisplayNames.entries
                              .map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              })
                              .toList(),
                        ),
                        const Divider(height: 24),
                        Text(
                          l10n.licensesSection,
                          style: theme.textTheme.titleSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            showLicensePage(
                              context: context,
                              applicationName: l10n.appTitle,
                              applicationVersion: _packageInfo != null
                                  ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                                  : null,
                            );
                          },
                          child: Text(l10n.licenses),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fixed footer section
            const Divider(height: 24),
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  if (_packageInfo != null)
                    Text(
                      '${l10n.version} ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

/// Download button, or progress and a cancel button while downloading.
class _ModelDownloadControls extends ConsumerWidget {
  final HomeState state;

  const _ModelDownloadControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notifier = ref.read(homeViewModelProvider.notifier);
    final progress = state.modelDownloadProgress;
    final error = state.modelDownloadError;
    final size = '${(_modelBytes / 1e6).round()} MB';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progress == null)
          TextButton.icon(
            onPressed: notifier.downloadModel,
            icon: const Icon(Icons.download),
            label: Text(l10n.downloadModel(size)),
          )
        else
          Row(
            children: [
              Expanded(child: LinearProgressIndicator(value: progress)),
              const SizedBox(width: 8),
              Text(
                l10n.downloadingModel((progress * 100).floor()),
                style: theme.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: notifier.cancelModelDownload,
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ],
          ),
        if (error != null)
          Text(
            l10n.modelDownloadFailed(error),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  static final _modelBytes = ModelDownloader.defaultFiles.fold<int>(
    0,
    (n, f) => n + f.size,
  );
}
