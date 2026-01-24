import 'package:flutter/material.dart';
import '../models/build_progress.dart';

class BuildProgressIndicator extends StatelessWidget {
  final BuildProgress progress;

  const BuildProgressIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress.currentStep,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.percentage > 0 ? progress.percentage : null,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 8),
        if (progress.currentFile.isNotEmpty)
          Text(
            'Processing: ${progress.currentFile}',
            style: theme.textTheme.bodySmall,
          ),
        if (progress.totalFiles > 0)
          Text(
            '${progress.processedFiles} / ${progress.totalFiles} files',
            style: theme.textTheme.bodySmall,
          ),
        if (progress.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.error!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  void didUpdateWidget(LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
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
