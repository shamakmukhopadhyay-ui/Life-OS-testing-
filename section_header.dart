import 'package:flutter/material.dart';

/// A reusable section title row.
///
/// Used here for "Today's Objectives" and "Today's Tasks," but it has no
/// knowledge of either — any future feature introducing a titled list
/// section (e.g. Notes' "Recent Entries") can reuse this instead of each
/// feature styling its own section title independently.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
