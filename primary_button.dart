import 'package:flutter/material.dart';

/// A thin, opinionated wrapper around Material 3's [FilledButton].
///
/// Every "primary action" in the app — Add Task, Save Note, Log Expense —
/// should use this instead of calling [FilledButton] directly. That way,
/// if we ever want every primary button in the app to change shape, add
/// haptics, or add a loading spinner, it's a one-file change instead of a
/// find-and-replace across every feature.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
