import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backlink_engine.dart';
import 'documents_list_provider.dart';

/// The whole-vault link graph, computed once per [documentsProvider]
/// value. Private — [documentLinksProvider] below is the public API;
/// this is purely its shared input, same "parse/build once" shape as
/// every `_...Provider` before it (Sprint 18's
/// `_documentsWithMetadataProvider`, Sprint 21's
/// `_searchDocumentsWithMetadataProvider`).
final _linkGraphProvider =
    Provider.autoDispose<AsyncValue<Map<String, DocumentLinks>>>((ref) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (docs) => AsyncValue.data(BacklinkEngine.buildGraph(docs)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Outgoing links, backlinks, and broken links for the document at
/// [path] — Sprint 22 Task 4.
///
/// Keyed by `path` (a `String`), not by `Document` — unlike Sprint 17's
/// `documentMetadataProvider.family<..., Document>`. `Document` has no
/// custom `==`, so a `Document`-keyed family caches per *instance*, not
/// per document; keying by path gets correct, value-based cache sharing
/// for free, since two `String`s with the same characters are already
/// `==`. Every consumer of this provider (Task 5's UI) already has the
/// open document's path on hand, so this costs callers nothing.
final documentLinksProvider =
    Provider.autoDispose.family<AsyncValue<DocumentLinks>, String>(
  (ref, path) {
    final graphAsync = ref.watch(_linkGraphProvider);
    return graphAsync.when(
      data: (graph) => AsyncValue.data(BacklinkEngine.linksFor(path, graph)),
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    );
  },
);
