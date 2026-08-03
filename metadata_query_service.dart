import '../data/document_metadata_model.dart';
import '../data/document_model.dart';
import 'document_metadata_service.dart';

/// A [Document] paired with its already-parsed [DocumentMetadata].
///
/// Exists so [MetadataQueryService]'s filter methods never need to parse
/// anything themselves — see [MetadataQueryService.withMetadata].
class DocumentWithMetadata {
  const DocumentWithMetadata(this.document, this.metadata);

  final Document document;
  final DocumentMetadata metadata;
}

/// Queries a document list by metadata — type, tags, favorite, pinned.
///
/// Sprint 18. Deliberately has no repository dependency at all: it only
/// ever operates on a [List<Document>] (or [List<DocumentWithMetadata>])
/// handed to it, which is what "keep repository interfaces unchanged"
/// means here — this service adds a new way to *look at* documents
/// without either `DocumentRepository` implementation knowing this
/// feature exists.
///
/// Static and dependency-free, same reasoning as [DocumentMetadataService]:
/// every method is a pure function of its input.
class MetadataQueryService {
  MetadataQueryService._(); // not instantiable

  /// Parses every document's metadata exactly once.
  ///
  /// Callers that need more than one filter over the same document list
  /// (Sprint 18's Views screen needs favorites, pinned, *and* journal
  /// from the same underlying list) should call this once and pass the
  /// result to each filter below, rather than have every filter re-parse
  /// the same documents independently. See documentsWithMetadataProvider
  /// in document_views_provider.dart for where this actually happens.
  static List<DocumentWithMetadata> withMetadata(List<Document> documents) {
    return documents
        .map((d) => DocumentWithMetadata(d, DocumentMetadataService.parse(d)))
        .toList();
  }

  static List<Document> favorites(List<DocumentWithMetadata> documents) {
    return [
      for (final d in documents)
        if (d.metadata.favorite) d.document,
    ];
  }

  static List<Document> pinned(List<DocumentWithMetadata> documents) {
    return [
      for (final d in documents)
        if (d.metadata.pinned) d.document,
    ];
  }

  /// Matches [DocumentMetadata.type] exactly (case-sensitive) — e.g.
  /// `byType(documents, 'journal')` for Sprint 18's Journal view.
  static List<Document> byType(
    List<DocumentWithMetadata> documents,
    String type,
  ) {
    return [
      for (final d in documents)
        if (d.metadata.type == type) d.document,
    ];
  }

  /// Not wired to any Views screen section yet — Task 3 only asks for
  /// Favorites/Pinned/Journal/Recent — but Task 1 explicitly lists tags
  /// as something this service should support, so it's here, tested,
  /// and ready for whenever a tag-based view is wanted.
  static List<Document> byTag(
    List<DocumentWithMetadata> documents,
    String tag,
  ) {
    return [
      for (final d in documents)
        if (d.metadata.tags.contains(tag)) d.document,
    ];
  }
}
