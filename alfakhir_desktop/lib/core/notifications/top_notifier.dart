import 'package:flutter/material.dart';

class TopNotifier {
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade700);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, Colors.orange.shade800);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red.shade700);
  }

  static void _show(BuildContext context, String message, Color bg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
