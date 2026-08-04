import 'package:flutter/material.dart';

/// Shared SnackBar notifications for Pantas-UI.
///
/// Prefer these helpers over calling [ScaffoldMessenger.showSnackBar] directly
/// so message presentation stays consistent across screens.
class AppNotify {
  AppNotify._();

  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, action: action, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(context, message, action: action, duration: duration);
  }

  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, action: action, duration: duration);
  }

  static void _show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    required Duration duration,
  }) {
    final text = message.trim();
    if (text.isEmpty) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
