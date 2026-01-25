import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_localizations.dart';
import '../models/build_progress.dart';
import '../services/mpq_builder_service.dart';
import '../widgets/diablo_button.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends StatefulWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  const HomeScreen({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _assetsPathController;
  late final TextEditingController _outputPathController;
  bool _isBuilding = false;

  static String? _getDefaultAssetsPath() {
    return kDebugMode ? '/Users/seiji/dev/psx-tools/ps1_assets' : null;
  }

  static String? _getDefaultOutputPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return p.join(
          home,
          'Library',
          'Application Support',
          'diasurgical',
          'devilution',
        );
      }
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        return p.join(appData, 'diasurgical', 'devilution');
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return p.join(home, '.local', 'share', 'diasurgical', 'devilution');
      }
    }
    return null;
  }

  BuildProgress? _progress;
  StreamSubscription<BuildProgress>? _buildSubscription;

  final MpqBuilderService _builderService = MpqBuilderService();

  // Language display names
  static const Map<String, String> _languageNames = {
    'system': 'System Default',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'zh_CN': '简体中文',
    'zh_TW': '繁體中文',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'pt_BR': 'Português (Brasil)',
    'ru': 'Русский',
    'uk': 'Українська',
    'pl': 'Polski',
    'cs': 'Čeština',
    'hu': 'Magyar',
    'ro': 'Română',
    'bg': 'Български',
    'hr': 'Hrvatski',
    'sv': 'Svenska',
    'da': 'Dansk',
    'fi': 'Suomi',
    'et': 'Eesti',
    'el': 'Ελληνικά',
    'tr': 'Türkçe',
    'be': 'Беларуская',
  };

  @override
  void initState() {
    super.initState();
    _assetsPathController = TextEditingController(
      text: _getDefaultAssetsPath(),
    );
    _outputPathController = TextEditingController(
      text: _getDefaultOutputPath(),
    );
  }

  @override
  void dispose() {
    _assetsPathController.dispose();
    _outputPathController.dispose();
    _buildSubscription?.cancel();
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

  Future<void> _startBuild() async {
    final assetsPath = _assetsPathController.text.trim();
    final outputPath = _outputPathController.text.trim();
    if (assetsPath.isEmpty || outputPath.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isBuilding = true;
      _progress = BuildProgress(currentStep: l10n.starting);
    });

    _buildSubscription = _builderService
        .build(assetsPath, outputPath, l10n)
        .listen(
          (progress) {
            setState(() {
              _progress = progress;
            });
          },
          onDone: () {
            setState(() {
              _isBuilding = false;
            });
          },
          onError: (error) {
            setState(() {
              _isBuilding = false;
              _progress = _progress?.copyWith(
                error: error.toString(),
                isComplete: true,
              );
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentKey = _getLocaleKey(widget.currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/appbar_background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          // Debug Language Selector (only in debug mode)
          if (kDebugMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              tooltip: 'Debug: Change Language',
              initialValue: currentKey,
              onSelected: (String key) {
                widget.onLocaleChanged(_parseLocaleKey(key));
              },
              itemBuilder: (BuildContext context) {
                return _languageNames.entries.map((entry) {
                  final isSelected = entry.key == currentKey;
                  return PopupMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(entry.value),
                        if (entry.key != 'system') ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${entry.key})',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFolderSelector(
              theme: theme,
              label: l10n.inputFolder,
              hint: l10n.inputFolderHint,
              controller: _assetsPathController,
              onBrowse: _isBuilding ? null : _selectAssetsFolder,
              enabled: !_isBuilding,
            ),
            const SizedBox(height: 12),
            _buildFolderSelector(
              theme: theme,
              label: l10n.outputFolder,
              hint: l10n.outputFolderHint,
              controller: _outputPathController,
              onBrowse: _isBuilding ? null : _selectOutputFolder,
              enabled: !_isBuilding,
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
                    !_isBuilding;
                return DiabloButton(
                  onPressed: canBuild ? _startBuild : null,
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isBuilding)
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
                      Text(_isBuilding ? l10n.building : l10n.buildMpq),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_progress != null) ...[
              BuildProgressIndicator(progress: _progress!),
              const SizedBox(height: 12),
              Expanded(
                child: LogViewer(
                  key: ValueKey(_progress!.logs.length),
                  logs: _progress!.logs,
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

  Widget _buildFolderSelector({
    required ThemeData theme,
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback? onBrowse,
    required bool enabled,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DiabloButton(
          onPressed: onBrowse,
          child: Text(AppLocalizations.of(context)!.browse),
        ),
      ],
    );
  }
}
