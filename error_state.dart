import 'package:flutter/material.dart';

/// A generic "this failed to load" view for a failed async load.
///
/// Extracted from the inline error block ObjectivesScreen already built
/// for itself (icon + title + muted error text) so the next list-based
/// screen — Documents, in Sprint 16 — doesn't re-duplicate that same
/// layout. ObjectivesScreen's own inline version is left exactly as it
/// was; retrofitting it to use this widget would touch approved,
/// unrelated code and is a separate cleanup, not part of this sprint.
///
/// Lives in `core/widgets` for the same reason as [EmptyState]: it has
/// zero knowledge of any specific feature's data.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.error,
  });

  /// A short, user-facing description of what failed.
  final String message;

  /// The underlying error, rendered as a smaller, muted line below
  /// [message] when provided. Optional because not every caller has
  /// (or wants to show) the raw error object.
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
