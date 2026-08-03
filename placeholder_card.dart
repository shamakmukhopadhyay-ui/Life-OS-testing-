import 'package:flutter/material.dart';

/// A lightweight "not built yet" placeholder for a V2 shell section —
/// LifeOS V2-01 (App Shell Migration).
///
/// Deliberately inert by default: no `onTap`, no state, no provider
/// dependency. Every screen this sprint adds (Today's six sections,
/// Library's nine, Home's four new ones) renders its placeholder
/// content with this one shared widget rather than each inventing its
/// own, so the "coming soon" look is consistent everywhere and there's
/// exactly one place to evolve it later, per section, into something
/// real.
///
/// [trailing] added in V2-02, purely optional — every existing call
/// site across Home/Today/Library that doesn't pass it renders exactly
/// as before. Added specifically for Focus Mode's "Start Session"
/// button (V2-02 Task 5): a button, unlike [subtitle]'s plain text,
/// needed a real widget slot, not a new parameter type bolted onto an
/// existing one.
class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
