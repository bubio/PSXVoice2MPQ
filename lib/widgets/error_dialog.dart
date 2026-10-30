import 'package:flutter/material.dart';

/// Shows a modal error dialog with a selectable message
void showErrorDialog(BuildContext context, String title, String errorMessage) {
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
