import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_model.dart';
import 'documents_list_provider.dart';
import 'metadata_query_service.dart';

/// Parses metadata for every document in [documentsProvider] exactly
/// once. Private — the four view providers below are what the rest of
/// the app should use; this is purely their shared, internal input.
///
/// `.autoDispose` for the same reason as documentMetadataProvider
/// (Sprint 17): nothing here needs to outlive whoever is watching it.
final _documentsWithMetadataProvider =
    Provider.autoDispose<AsyncValue<List<DocumentWithMetadata>>>((ref) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (docs) => AsyncValue.data(MetadataQueryService.withMetadata(docs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Documents with `favorite: true` in frontmatter.
final favoriteDocumentsProvider =
    Provider.autoDispose<AsyncValue<List<Document>>>((ref) {
  final withMetadata = ref.watch(_documentsWithMetadataProvider);
  return withMetadata.when(
    data: (docs) => AsyncValue.data(MetadataQueryService.favorites(docs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Documents with `pinned: true` in frontmatter.
final pinnedDocumentsProvider =
    Provider.autoDispose<AsyncValue<List<Document>>>((ref) {
  final withMetadata = ref.watch(_documentsWithMetadataProvider);
  return withMetadata.when(
    data: (docs) => AsyncValue.data(MetadataQueryService.pinned(docs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Documents with `type: journal` in frontmatter.
final journalDocumentsProvider =
    Provider.autoDispose<AsyncValue<List<Document>>>((ref) {
  final withMetadata = ref.watch(_documentsWithMetadataProvider);
  return withMetadata.when(
    data: (docs) =>
        AsyncValue.data(MetadataQueryService.byType(docs, 'journal')),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// How many documents the Recent view shows. Favorites/Pinned/Journal
/// are naturally bounded by user intent (only documents someone
/// explicitly marked that way), but "every document sorted by date"
/// would grow unbounded, so this one view gets an explicit cap. Not
/// specified by the sprint brief — a reasonable default, easy to
/// change if you want a different number.
const int recentDocumentsLimit = 10;

/// The [recentDocumentsLimit] most recently modified documents.
///
/// Deliberately watches [documentsProvider] directly, *not*
/// [_documentsWithMetadataProvider] — DocumentsNotifier already sorts by
/// `updatedAt` descending (Sprint 16), so "recent" needs no metadata
/// parsing at all. This is Task 6's "parse metadata only when necessary"
/// in its most literal form: for this one view, it's never necessary.
final recentDocumentsProvider =
    Provider.autoDispose<AsyncValue<List<Document>>>((ref) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (docs) =>
        AsyncValue.data(docs.take(recentDocumentsLimit).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
