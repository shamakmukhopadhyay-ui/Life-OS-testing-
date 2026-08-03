import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_card.dart';
import '../../../core/widgets/section_header.dart';

/// Library tab root — LifeOS V2-01.
///
/// Nine named sections, all [PlaceholderCard]s — "only placeholders, no
/// filtering yet," per this sprint's scope. A future sprint generalizes
/// the existing Documents feature's type/tag filtering (Sprint 21's
/// MetadataQueryService) to back these for real, rather than this
/// screen inventing its own filtering logic now.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _sections = [
    (Icons.apps_outlined, 'All'),
    (Icons.description_outlined, 'Documents'),
    (Icons.today_outlined, 'Daily Notes'),
    (Icons.menu_book_outlined, 'Study Guides'),
    (Icons.style_outlined, 'Flashcards'),
    (Icons.quiz_outlined, 'Quizzes'),
    (Icons.chat_outlined, 'AI Chats'),
    (Icons.attach_file_outlined, 'Attachments'),
    (Icons.archive_outlined, 'Archive'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Library'),
          const SizedBox(height: 8),
          for (final (icon, title) in _sections) ...[
            PlaceholderCard(icon: icon, title: title),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 76),
        ],
      ),
    );
  }
}
