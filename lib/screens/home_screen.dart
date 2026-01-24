import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/build_progress.dart';
import '../services/mpq_builder_service.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedAssetsPath = '/Users/seiji/dev/psx-tools/ps1_assets';
  String? _selectedOutputPath = '/Users/seiji/dev/psx-tools/ps1_assets';
  bool _isBuilding = false;
  BuildProgress? _progress;
  StreamSubscription<BuildProgress>? _buildSubscription;

  final MpqBuilderService _builderService = MpqBuilderService();

  @override
  void dispose() {
    _buildSubscription?.cancel();
    super.dispose();
  }

  Future<void> _selectAssetsFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select ps1_assets folder',
    );
    if (result != null) {
      setState(() {
        _selectedAssetsPath = result;
      });
    }
  }

  Future<void> _selectOutputFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output folder for MPQ files',
    );
    if (result != null) {
      setState(() {
        _selectedOutputPath = result;
      });
    }
  }

  Future<void> _startBuild() async {
    if (_selectedAssetsPath == null || _selectedOutputPath == null) return;

    setState(() {
      _isBuilding = true;
      _progress = const BuildProgress(currentStep: 'Starting...');
    });

    _buildSubscription = _builderService
        .build(_selectedAssetsPath!, _selectedOutputPath!)
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('PSX MPQ Converter'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFolderSelector(
              theme: theme,
              label: 'Input Folder',
              path: _selectedAssetsPath,
              onBrowse: _isBuilding ? null : _selectAssetsFolder,
            ),
            const SizedBox(height: 12),
            _buildFolderSelector(
              theme: theme,
              label: 'Output Folder',
              path: _selectedOutputPath,
              onBrowse: _isBuilding ? null : _selectOutputFolder,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_selectedAssetsPath != null &&
                      _selectedOutputPath != null &&
                      !_isBuilding)
                  ? _startBuild
                  : null,
              icon: _isBuilding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.build, size: 18),
              label: Text(_isBuilding ? 'Building...' : 'Build MPQ'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (_progress != null) ...[
              BuildProgressIndicator(progress: _progress!),
              const SizedBox(height: 12),
              Expanded(
                child: LogViewer(logs: _progress!.logs),
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
                        'Click Build to start',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                        ),
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
    required String? path,
    required VoidCallback? onBrowse,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              path ?? 'Not selected',
              style: TextStyle(
                fontSize: 12,
                color: path != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: FilledButton(
            onPressed: onBrowse,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Browse', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
