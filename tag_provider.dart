import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_model.dart';
import 'documents_list_provider.dart';
import 'metadata_query_service.dart';
import 'search_service.dart';

/// Tag-derived views over [documentsProvider] — Sprint 21 Task 5's Tag
/// Explorer, and the tap-through to a single tag's documents.
///
/// Shaped exactly like document_views_provider.dart's Favorites/Pinned/
/// Journal providers (Sprint 18): watch [documentsProvider], parse
/// metadata, derive. That file's own `_documentsWithMetadataProvider` is
/// private to it, so rather than exporting a Sprint 18 internal or
/// touching its approved code to share it, each provider below calls
/// [MetadataQueryService.withMetadata] itself. That's a small, deliberate
/// duplication — cheap for the personal-vault sizes this app targets
/// (see search_service.dart's own "fast enough for large vaults" note) —
/// flagged in Technical Debt rather than left unexplained.
final tagCountsProvider =
    Provider.autoDispose<AsyncValue<List<TagCount>>>((ref) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (docs) => AsyncValue.data(
      SearchService.tagCounts(MetadataQueryService.withMetadata(docs)),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Every document carrying the given tag (exact match) — what
/// `TagDocumentsScreen` shows after tapping a tag on the Tag Explorer.
/// Built on [MetadataQueryService.byTag], which Sprint 18 already added
/// and tested for exactly this future use.
final documentsByTagProvider =
    Provider.autoDispose.family<AsyncValue<List<Document>>, String>(
  (ref, tag) {
    final documentsAsync = ref.watch(documentsProvider);
    return documentsAsync.when(
      data: (docs) => AsyncValue.data(
        MetadataQueryService.byTag(
          MetadataQueryService.withMetadata(docs),
          tag,
        ),
      ),
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    );
  },
);
