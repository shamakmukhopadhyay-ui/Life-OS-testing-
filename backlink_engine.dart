import '../data/document_model.dart';
import 'wiki_link_service.dart';

/// One outgoing [WikiLink] together with the [Document] it resolved to.
///
/// Keeping [link] alongside [document] (rather than just returning the
/// documents) preserves each occurrence's own alias/display text — two
/// links to the same target with different aliases (e.g.
/// `[[Page|first mention]]` and `[[Page|second mention]]`) stay
/// distinguishable.
class ResolvedLink {
  const ResolvedLink({required this.link, required this.document});

  final WikiLink link;
  final Document document;
}

/// A document's full link picture — Sprint 22 Task 3.
class DocumentLinks {
  const DocumentLinks({
    required this.outgoing,
    required this.incoming,
    required this.broken,
  });

  static const empty = DocumentLinks(outgoing: [], incoming: [], broken: []);

  /// Every wiki link this document contains that resolved to another
  /// document — one entry per occurrence, not deduplicated by target:
  /// referencing the same page twice with different aliases is two
  /// entries here, since each occurrence's own display text is useful
  /// to preserve.
  final List<ResolvedLink> outgoing;

  /// Every other document that links here — deduplicated by source
  /// document, unlike [outgoing]. From the target's side there's no
  /// per-occurrence alias to preserve, so a document that mentions this
  /// one three times should still just appear once in "documents that
  /// link here," not three times.
  final List<Document> incoming;

  /// Every wiki link this document contains that did *not* resolve to
  /// any document — one entry per occurrence, same reasoning as
  /// [outgoing].
  final List<WikiLink> broken;
}

/// Builds the vault-wide link graph — Sprint 22 Task 3.
///
/// Static and dependency-free, same shape as every other service this
/// project has built. Reuses [WikiLinkService]/[DocumentIndex] for
/// extraction and resolution rather than reimplementing either.
///
/// Touches no repository and no SQLite table — the graph is derived
/// entirely from [Document.content] (already in memory via
/// `documentsProvider`), recomputed fresh each time [buildGraph] is
/// called rather than persisted anywhere. "Reuse repositories" (Task 3)
/// and "no database migration" (Task 3/7) both hold because this layer
/// never needs to ask a repository for anything beyond the document
/// list it's handed — no new repository call, let alone a new method
/// or table.
class BacklinkEngine {
  BacklinkEngine._(); // not instantiable

  /// Computes every document's [DocumentLinks] in a single pass over
  /// [documents], keyed by path.
  ///
  /// This is Task 4's "avoid unnecessary recomputation" in its most
  /// direct form: incoming links for any one document can only be
  /// known by having already examined every *other* document's
  /// outgoing links, so there's no cheaper way to answer "what links
  /// here?" for a single document in isolation — doing the full pass
  /// once and indexing the result by path is the efficient shape,
  /// not a shortcut being skipped. Callers needing just one document's
  /// links should still call this once (e.g. via a shared provider)
  /// and look up their path, rather than each calling it independently.
  static Map<String, DocumentLinks> buildGraph(List<Document> documents) {
    final index = DocumentIndex(documents);

    final outgoingByPath = <String, List<ResolvedLink>>{};
    final brokenByPath = <String, List<WikiLink>>{};
    // Target path -> {source path -> source document}, so a document
    // referencing the same target multiple times contributes only one
    // entry to that target's incoming list.
    final incomingByPath = <String, Map<String, Document>>{};

    for (final document in documents) {
      final links = WikiLinkService.extractLinks(document.content);
      final outgoing = <ResolvedLink>[];
      final broken = <WikiLink>[];

      for (final link in links) {
        final resolved = WikiLinkService.resolve(link, index);
        if (resolved == null) {
          broken.add(link);
          continue;
        }
        outgoing.add(ResolvedLink(link: link, document: resolved));
        incomingByPath
            .putIfAbsent(resolved.path, () => {})[document.path] = document;
      }

      outgoingByPath[document.path] = outgoing;
      brokenByPath[document.path] = broken;
    }

    return {
      for (final document in documents)
        document.path: DocumentLinks(
          outgoing: outgoingByPath[document.path] ?? const [],
          incoming: incomingByPath[document.path]?.values.toList() ??
              const [],
          broken: brokenByPath[document.path] ?? const [],
        ),
    };
  }

  /// [graph]'s entry for [path], or [DocumentLinks.empty] if [path]
  /// isn't in it (e.g. the document was deleted between building the
  /// graph and looking it up).
  static DocumentLinks linksFor(String path, Map<String, DocumentLinks> graph) {
    return graph[path] ?? DocumentLinks.empty;
  }
}
