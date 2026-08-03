import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/document_model.dart';
import '../logic/documents_list_provider.dart';
import '../logic/metadata_query_service.dart';
import '../logic/search_service.dart';
import 'widgets/search_result_card.dart';

/// Global search across every document's title, content, and metadata —
/// Sprint 21 Tasks 1/2/4.
///
/// The query itself is plain widget state (a [TextEditingController]),
/// not a Riverpod provider: this project has no precedent for a
/// keystroke-driven provider (DocumentEditorScreen's title/content
/// fields use the same StatefulWidget + controller shape, Sprint 20),
/// and a `.family` provider keyed by query text would mint — and then
/// need to autoDispose — a fresh provider instance on every keystroke,
/// which is worse, not more idiomatic. [SearchService.search] is a
/// synchronous, index-free linear scan by design (see its own doc
/// comment), so recomputing it in [build] on every keystroke is exactly
/// as cheap as the service already assumes.
///
/// Registered at the `/search` route. Like Documents (Sprint 16) and
/// Views (Sprint 18) before it, not yet linked from any navigation entry
/// point — bottom nav is still a fixed 4 tabs with no free slot — left
/// as your call rather than assumed, matching that same precedent.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search documents…',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium,
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load documents to search',
          error: error,
        ),
        data: (documents) => _SearchBody(documents: documents, query: _query),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.documents, required this.query});

  final List<Document> documents;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search your documents',
        message: 'Type to search titles, content, and tags.',
      );
    }

    final withMetadata = MetadataQueryService.withMetadata(documents);
    final results = SearchService.search(withMetadata, query);

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        message: 'No documents match "${query.trim()}".',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return SearchResultCard(
          document: doc,
          snippet: SearchService.snippetFor(doc, query),
          onTap: () => context.push('/document', extra: doc),
        );
      },
    );
  }
}
