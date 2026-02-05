import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/build_progress.dart';
import 'diablo_progress_bar.dart';

class BuildProgressIndicator extends StatefulWidget {
  final BuildProgress progress;

  const BuildProgressIndicator({
    super.key,
    required this.progress,
  });

  @override
  State<BuildProgressIndicator> createState() =>
      _BuildProgressIndicatorState();
}

class _BuildProgressIndicatorState extends State<BuildProgressIndicator> {
  late final DateTime _buildStartTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _buildStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_buildStartTime);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  String _getLocalizedStep(AppLocalizations l10n) {
    final streamName = widget.progress.streamName ?? '';

    switch (widget.progress.stepKey) {
      case BuildStepKey.initializing:
        return l10n.initializing;
      case BuildStepKey.extractingBinaries:
        return l10n.extractingBinaries;
      case BuildStepKey.findingStreamFiles:
        return l10n.findingStreamFiles;
      case BuildStepKey.extractingStream:
        return l10n.extractingStream(streamName);
      case BuildStepKey.convertingVagFiles:
        return l10n.convertingVagFiles(streamName);
      case BuildStepKey.enhancingAudio:
        return l10n.enhancingAudio(streamName);
      case BuildStepKey.convertingToMp3:
        return l10n.convertingToMp3(streamName);
      case BuildStepKey.creatingMpq:
        return l10n.creatingMpq(streamName);
      case BuildStepKey.cleaningUp:
        return l10n.cleaningUp;
      case BuildStepKey.complete:
        return l10n.complete;
      case null:
        return widget.progress.currentStep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final progress = widget.progress;
    final hasError = progress.error != null || progress.errorKey != null;
    final isComplete = progress.isComplete;

    // Stop timer when build is done
    if ((isComplete || hasError) && _timer != null) {
      _timer?.cancel();
      _timer = null;
      _elapsed = DateTime.now().difference(_buildStartTime);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? l10n.buildFailed : _getLocalizedStep(l10n),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: hasError ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(height: 8),
        DiabloProgressBar(
          value: hasError
              ? 0.0
              : (progress.percentage > 0 ? progress.percentage : null),
        ),
        const SizedBox(height: 8),
        if (!hasError && progress.currentFile.isNotEmpty)
          Text(
            l10n.processing(progress.currentFile),
            style: theme.textTheme.bodySmall,
          ),
        if (!hasError && progress.totalFiles > 0)
          Text(
            '${l10n.filesProgress(progress.processedFiles, progress.totalFiles)}'
            '  ${_formatDuration(_elapsed)}',
            style: theme.textTheme.bodySmall,
          ),
        if (!hasError && progress.totalFiles == 0)
          Text(
            _formatDuration(_elapsed),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

class LogViewer extends StatefulWidget {
  final List<String> logs;

  const LogViewer({
    super.key,
    required this.logs,
  });

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom on initial build if there are logs
    if (widget.logs.isNotEmpty) {
      _scrollToBottom();
    }
  }

  @override
  void didUpdateWidget(LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length > oldWidget.logs.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: widget.logs.length,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(index),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SelectableText(
              widget.logs[index],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }
}
