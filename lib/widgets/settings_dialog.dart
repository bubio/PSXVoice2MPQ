import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/path_constants.dart';
import '../core/constants/stream_constants.dart';
import '../l10n/app_localizations.dart';
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
                        // AudioSR section (hidden when feature is disabled)
                        if (AppConstants.enableAudioSr) ...[
                        Text('AudioSR', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.enableAudioSr),
                          subtitle: Text(
                            l10n.audioSrNote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          value: state.useAudioSr,
                          onChanged: state.audioSrAvailable
                              ? (value) {
                                  ref
                                      .read(homeViewModelProvider.notifier)
                                      .setUseAudioSr(value ?? false);
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                state.audioSrAvailable
                                    ? (state.audioSrPath ?? '')
                                    : l10n.audioSrNotFound,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: state.audioSrAvailable
                                      ? theme.colorScheme.outline
                                      : theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          dialogTitle:
                                              'Select audiosr executable',
                                          type: FileType.any,
                                        );
                                    if (result != null &&
                                        result.files.single.path != null) {
                                      ref
                                          .read(homeViewModelProvider.notifier)
                                          .setAudioSrPath(
                                            result.files.single.path!,
                                          );
                                    }
                                  },
                                  child: Text(l10n.browseAudioSr),
                                ),
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.audioSrUseCpu,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        state.useAudioSr &&
                                            state.audioSrAvailable
                                        ? null
                                        : theme.disabledColor,
                                  ),
                                ),
                                value: state.audioSrUseCpu,
                                onChanged:
                                    state.useAudioSr && state.audioSrAvailable
                                    ? (value) {
                                        ref
                                            .read(
                                              homeViewModelProvider.notifier,
                                            )
                                            .setAudioSrUseCpu(value ?? false);
                                      }
                                    : null,
                              ),
                              Row(
                                children: [
                                  Text(
                                    l10n.audioSrChunkSeconds,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          state.useAudioSr &&
                                              state.audioSrAvailable
                                          ? null
                                          : theme.disabledColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  DropdownButton<int>(
                                    value: state.audioSrChunkSeconds,
                                    onChanged:
                                        state.useAudioSr &&
                                            state.audioSrAvailable
                                        ? (value) {
                                            if (value != null) {
                                              ref
                                                  .read(
                                                    homeViewModelProvider
                                                        .notifier,
                                                  )
                                                  .setAudioSrChunkSeconds(
                                                    value,
                                                  );
                                            }
                                          }
                                        : null,
                                    items: [1, 2, 3, 4, 5]
                                        .map(
                                          (v) => DropdownMenuItem<int>(
                                            value: v,
                                            child: Text('$v'),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 24),
                        ],
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
