import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/frontmatter_parser.dart';
import '../data/document_metadata_model.dart';
import '../data/document_model.dart';

/// Derives a [DocumentMetadata] from a [Document]'s content.
///
/// Static and dependency-free, like [DailyNoteService] — there's nothing
/// to inject; parsing is a pure function of the document's own text.
/// Deliberately always re-parses [Document.content] directly rather than
/// trusting [Document.frontmatter]/[Document.tags]: those fields are only
/// reliably populated for Obsidian-backed documents today (see
/// ObsidianDocumentRepository's read path). Parsing content directly
/// here means this works identically for every vault type, present or
/// future, without this class ever needing to know or care which one
/// produced the document — exactly the "metadata over document types"
/// principle this sprint exists to establish.
class DocumentMetadataService {
  DocumentMetadataService._(); // not instantiable

  /// Parses [document]'s frontmatter and returns a [DocumentMetadata],
  /// falling back to the document's own title/timestamps for anything
  /// frontmatter doesn't specify. Never throws — malformed or absent
  /// frontmatter both resolve to sensible defaults via
  /// [DocumentMetadata.fromFrontmatter].
  static DocumentMetadata parse(Document document) {
    final frontmatter = parseFrontmatter(document.content);
    return DocumentMetadata.fromFrontmatter(
      frontmatter,
      fallbackTitle: document.title,
      fallbackCreated: document.createdAt,
      fallbackModified: document.updatedAt,
    );
  }
}

/// Reactive, per-document metadata lookup for widgets.
///
/// `.autoDispose` because this caches per [Document] *instance* (Document
/// has no custom `==`, so equal-but-distinct instances of the same
/// document don't share a cache entry) — without autoDispose this would
/// accumulate one entry per Document object ever watched, for the life
/// of the app. Parsing is cheap enough that re-deriving on the next
/// watch, rather than keeping every past instance's result alive
/// indefinitely, is the right trade-off here.
///
/// Usage: `ref.watch(documentMetadataProvider(document))`.
final documentMetadataProvider =
    Provider.autoDispose.family<DocumentMetadata, Document>(
  (ref, document) => DocumentMetadataService.parse(document),
);
