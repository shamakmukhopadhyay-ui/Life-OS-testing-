import 'package:flutter/material.dart';

/// A titled section card for the Day Summary screen.
///
/// Used for every section of the daily summary (Objectives completed,
/// Tasks completed, Daily Score, Reflection, Notes). All sections share
/// the same visual shell — icon, title, optional trailing badge, and a
/// scrollable body area — so the summary screen composes cleanly without
/// repeating card scaffolding.
///
/// The [child] is the section's content. When content is empty the caller
/// should pass an [EmptyState]-style widget, not null, so the card always
/// renders with useful feedback rather than collapsing.
class DaySummarySection extends StatelessWidget {
  const DaySummarySection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Optional badge or label shown on the right of the header row
  /// (e.g. "3 / 5" completion count, or a score chip).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
