import 'package:flutter/material.dart';

import '../core/constants/stream_constants.dart';

class LanguageSelector extends StatelessWidget {
  final String currentKey;
  final ValueChanged<String> onSelected;

  const LanguageSelector({
    super.key,
    required this.currentKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: 'Debug: Change Language',
      initialValue: currentKey,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return StreamConstants.languageDisplayNames.entries.map((entry) {
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
    );
  }
}
