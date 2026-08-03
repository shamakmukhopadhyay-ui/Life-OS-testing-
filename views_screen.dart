import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/section_header.dart';
import '../data/document_model.dart';
import '../logic/document_views_provider.dart';
import '../logic/documents_list_provider.dart';
import 'widgets/document_list_card.dart';

/// Dynamic, metadata-driven document views — Sprint 18.
///
/// Every section here is generated from ordinary documents' frontmatter
/// (Sprint 17), not a separate document type: "Journal" is just
/// `type: journal` in a normal markdown file, exactly like every other
/// document. Nothing on this screen owns any data of its own — it only
/// reads from favoriteDocumentsProvider/pinnedDocumentsProvider/
/// journalDocumentsProvider/recentDocumentsProvider (all in
/// document_views_provider.dart).
///
/// Registered at the `/views` route. Like DocumentsListScreen in
/// Sprint 16, it isn't yet linked from any navigation entry point
/// (bottom nav is a fixed 4 tabs with no free slot) — left as your call
/// rather than assumed.
class ViewsScreen extends ConsumerWidget {
  const ViewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gates the whole screen on the one underlying load (documentsProvider)
    // rather than each section separately — avoids showing four
    // simultaneous spinners for what is, underneath, a single data
    // source. Each _ViewSection below still handles loading/error itself
    // too, as a safety net if that ever stops being true.
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Views')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load views',
          error: error,
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ViewSection(
              title: '⭐ Favorites',
              documentsAsync: ref.watch(favoriteDocumentsProvider),
              emptyIcon: Icons.star_border,
              emptyMessage: 'No favorite documents.',
            ),
            const SizedBox(height: 24),
            _ViewSection(
              title: '📌 Pinned',
              documentsAsync: ref.watch(pinnedDocumentsProvider),
              emptyIcon: Icons.push_pin_outlined,
              emptyMessage: 'No pinned documents.',
            ),
            const SizedBox(height: 24),
            _ViewSection(
              title: '📔 Journal',
              documentsAsync: ref.watch(journalDocumentsProvider),
              emptyIcon: Icons.menu_book_outlined,
              emptyMessage: 'No journal entries.',
            ),
            const SizedBox(height: 24),
            _ViewSection(
              title: '🕒 Recent',
              documentsAsync: ref.watch(recentDocumentsProvider),
              emptyIcon: Icons.access_time,
              emptyMessage: 'No documents yet.',
            ),
          ],
        ),
      ),
    );
  }
}

/// One titled section of the Views screen: a [SectionHeader], then
/// either a [DocumentListCard] per document, an [EmptyState], or an
/// [ErrorState] — never touches a provider or repository itself, so
/// this stays pure Presentation with no business logic of its own.
class _ViewSection extends StatelessWidget {
  const _ViewSection({
    required this.title,
    required this.documentsAsync,
    required this.emptyIcon,
    required this.emptyMessage,
  });

  final String title;
  final AsyncValue<List<Document>> documentsAsync;
  final IconData emptyIcon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 8),
        documentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorState(
            message: 'Could not load this section',
            error: error,
          ),
          data: (documents) {
            if (documents.isEmpty) {
              return EmptyState(icon: emptyIcon, title: emptyMessage);
            }
            // Reuses DocumentListCard exactly as Sprint 16 built it — no
            // rename/duplicate/delete callbacks here since Task 5 only
            // asks for tap-to-open. The action row still renders
            // (DocumentListCard's own documented behavior: a null
            // callback leaves its button visible but inert), which is
            // worth a look if it feels cluttered for this preview-style
            // context — flagged in Technical Debt rather than changed
            // here, since altering that behavior means touching
            // Sprint 16's approved widget.
            return Column(
              children: [
                for (final doc in documents)
                  DocumentListCard(
                    document: doc,
                    onTap: () => context.push('/document', extra: doc),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
