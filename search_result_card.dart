import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_helpers.dart';
import '../../data/document_model.dart';
import '../../logic/search_service.dart';

/// A single search result, shown as a Material 3 [Card].
///
/// A distinct widget from DocumentListCard (Sprint 16) rather than an
/// extension of it — Sprint 21 Task 4's highlighted snippet doesn't fit
/// DocumentListCard's plain-preview shape, and adding it there would mean
/// modifying that approved widget for a need only search has. Also skips
/// the rename/duplicate/delete action row entirely (tap-to-open only):
/// ViewsScreen (Sprint 18) reused DocumentListCard for a similarly
/// preview-style list and flagged its always-visible-but-inert action row
/// as Technical Debt there; a purpose-built widget here just doesn't
/// have the problem.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.document,
    required this.snippet,
    this.onTap,
  });

  final Document document;

  /// From [SearchService.snippetFor]. Null when the match was only in
  /// the title or metadata (not the body content) — [build] falls back
  /// to a plain, unhighlighted preview of the document's own content in
  /// that case, the same fallback its doc comment describes.
  final SearchSnippet? snippet;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _Snippet(document: document, snippet: snippet),
              const SizedBox(height: 6),
              Text(
                'Edited ${formatCompactDate(document.updatedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Snippet extends StatelessWidget {
  const _Snippet({required this.document, required this.snippet});

  final Document document;
  final SearchSnippet? snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.outline,
    );
    final currentSnippet = snippet;

    if (currentSnippet == null) {
      final preview = document.content.trim();
      if (preview.isEmpty) return const SizedBox.shrink();
      return Text(
        preview,
        style: baseStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final text = currentSnippet.text;
    final start = currentSnippet.matchStart;
    final end = start + currentSnippet.matchLength;

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              backgroundColor: theme.colorScheme.primaryContainer,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
