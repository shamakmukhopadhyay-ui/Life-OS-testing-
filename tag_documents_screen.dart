import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../logic/tag_provider.dart';
import 'widgets/document_list_card.dart';

/// Every document carrying one specific tag — reached by tapping a tag
/// on `TagExplorerScreen` (Sprint 21 Task 5).
///
/// Registered at the `/tag` route, with [tag] passed via `extra` rather
/// than a `:tag` path segment — the same reasoning the `/document` route
/// already gives for passing a whole `Document` via `extra`: a tag is a
/// free-form, user-authored frontmatter string (spaces, unicode, even
/// slashes are all valid), and encoding one safely into a URL path
/// segment isn't guaranteed the way `extra` is.
///
/// Reuses DocumentListCard exactly as ViewsScreen (Sprint 18) does for
/// its own filtered sections: tap-to-open only, no rename/duplicate/
/// delete callbacks. Same accepted trade-off ViewsScreen already flagged
/// in its Technical Debt (the action row stays visible but inert) — not
/// repeated here since it's already on record there.
class TagDocumentsScreen extends ConsumerWidget {
  const TagDocumentsScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsByTagProvider(tag));

    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load documents for this tag',
          error: error,
        ),
        data: (documents) {
          if (documents.isEmpty) {
            return const EmptyState(
              icon: Icons.label_outline,
              title: 'No documents with this tag',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return DocumentListCard(
                document: doc,
                onTap: () => context.push('/document', extra: doc),
              );
            },
          );
        },
      ),
    );
  }
}
