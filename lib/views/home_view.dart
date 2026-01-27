import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/build_state.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/diablo_button.dart';
import '../widgets/folder_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/progress_indicator.dart';

class HomeView extends ConsumerStatefulWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  const HomeView({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late final TextEditingController _assetsPathController;
  late final TextEditingController _outputPathController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(homeViewModelProvider);
    _assetsPathController = TextEditingController(text: state.assetsPath);
    _outputPathController = TextEditingController(text: state.outputPath);

    // Sync text controllers with ViewModel
    _assetsPathController.addListener(_onAssetsPathChanged);
    _outputPathController.addListener(_onOutputPathChanged);
  }

  String _getLocalizedError(AppLocalizations l10n, BuildErrorKey errorKey) {
    switch (errorKey) {
      case BuildErrorKey.smpqNotFound:
        return l10n.errorSmpqNotFound;
      case BuildErrorKey.noStreamFiles:
        return l10n.errorNoStreamFiles;
      case BuildErrorKey.outputDirectoryNotFound:
        return l10n.errorOutputDirectoryNotFound;
      case BuildErrorKey.unknown:
        return l10n.buildFailed;
    }
  }

  void _showErrorDialog(String title, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(errorMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onAssetsPathChanged() {
    ref
        .read(homeViewModelProvider.notifier)
        .setAssetsPath(_assetsPathController.text);
  }

  void _onOutputPathChanged() {
    ref
        .read(homeViewModelProvider.notifier)
        .setOutputPath(_outputPathController.text);
  }

  @override
  void dispose() {
    _assetsPathController.removeListener(_onAssetsPathChanged);
    _outputPathController.removeListener(_onOutputPathChanged);
    _assetsPathController.dispose();
    _outputPathController.dispose();
    super.dispose();
  }

  String _getLocaleKey(Locale? locale) {
    if (locale == null) return 'system';
    if (locale.countryCode != null) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  Locale? _parseLocaleKey(String key) {
    if (key == 'system') return null;
    final parts = key.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  Future<void> _selectAssetsFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectInputFolder,
    );
    if (result != null) {
      _assetsPathController.text = result;
    }
  }

  Future<void> _selectOutputFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectOutputFolder,
    );
    if (result != null) {
      _outputPathController.text = result;
    }
  }

  void _startBuild() {
    ref.read(homeViewModelProvider.notifier).startBuild();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(homeViewModelProvider);
    final currentKey = _getLocaleKey(widget.currentLocale);

    // Listen for error state changes and show alert
    ref.listen<HomeState>(homeViewModelProvider, (previous, next) {
      if (next.status == BuildStatus.error && previous?.status != BuildStatus.error) {
        final progress = next.progress;
        if (progress != null) {
          String errorMessage;
          if (progress.errorKey != null) {
            errorMessage = _getLocalizedError(l10n, progress.errorKey!);
          } else {
            errorMessage = progress.error ?? l10n.buildFailed;
          }
          _showErrorDialog(l10n.buildFailed, errorMessage);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/appbar_background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          if (kDebugMode)
            LanguageSelector(
              currentKey: currentKey,
              onSelected: (key) {
                widget.onLocaleChanged(_parseLocaleKey(key));
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FolderSelector(
              label: l10n.inputFolder,
              hint: l10n.inputFolderHint,
              controller: _assetsPathController,
              onBrowse: state.isBuilding ? null : _selectAssetsFolder,
              enabled: !state.isBuilding,
            ),
            const SizedBox(height: 12),
            FolderSelector(
              label: l10n.outputFolder,
              hint: l10n.outputFolderHint,
              controller: _outputPathController,
              onBrowse: state.isBuilding ? null : _selectOutputFolder,
              enabled: !state.isBuilding,
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: Listenable.merge([
                _assetsPathController,
                _outputPathController,
              ]),
              builder: (context, _) {
                final canBuild =
                    _assetsPathController.text.trim().isNotEmpty &&
                        _outputPathController.text.trim().isNotEmpty &&
                        !state.isBuilding;
                return DiabloButton(
                  onPressed: canBuild ? _startBuild : null,
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.isBuilding)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4C4A0),
                          ),
                        )
                      else
                        const Icon(Icons.build, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(state.isBuilding ? l10n.building : l10n.buildMpq),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (state.progress != null) ...[
              BuildProgressIndicator(progress: state.progress!),
              const SizedBox(height: 12),
              Expanded(
                child: LogViewer(
                  key: ValueKey(state.progress!.logs.length),
                  logs: state.progress!.logs,
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.clickBuildToStart,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
