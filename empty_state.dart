import 'package:flutter/material.dart';

/// A generic "nothing here yet" view.
///
/// Every list-based feature (Tasks, Habits, Notes, Finance) will need some
/// version of this when its list is empty. It lives in `core/widgets`
/// because it has zero knowledge of any specific feature's data — it just
/// takes an icon, a title, and an optional message.
///
/// Kept deliberately generic: it does NOT include a call-to-action button,
/// because whether that button says "Add Task" or "Log Expense" is a
/// feature-specific decision, not a core one.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
