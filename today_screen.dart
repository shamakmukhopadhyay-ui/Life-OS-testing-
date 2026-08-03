import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_card.dart';
import '../../../core/widgets/section_header.dart';

/// Today tab placeholder — LifeOS V2-01.
///
/// Will become the Daily Challenge workspace (the V2 architecture's
/// Today module) in a future sprint. For now every section below is
/// inert — [PlaceholderCard], not real data — per this sprint's "shell
/// only" scope. Deliberately does not reuse DayWorkspaceScreen's real
/// Daily Note flow from Sprint 23: that screen and its `/calendar/:date`
/// route are untouched and still fully reachable on their own; folding
/// Today into it is later integration work, not this sprint's.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  static const _sections = [
    (Icons.flag_outlined, 'Objectives'),
    (Icons.check_circle_outline, 'Tasks'),
    (Icons.description_outlined, 'Daily Notes'),
    (Icons.book_outlined, 'Journal'),
    (Icons.emoji_events_outlined, 'Daily Score'),
    (Icons.timeline_outlined, 'Timeline'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Today'),
          const SizedBox(height: 8),
          for (final (icon, title) in _sections) ...[
            PlaceholderCard(
              icon: icon,
              title: title,
              subtitle: 'Coming to Today in a future sprint.',
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 76),
        ],
      ),
    );
  }
}
