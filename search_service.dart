import '../data/document_model.dart';
import 'metadata_query_service.dart';

/// A tag and how many documents carry it — Sprint 21 Task 5's Tag
/// Explorer.
class TagCount {
  const TagCount(this.tag, this.count);

  final String tag;
  final int count;
}

/// An excerpt of a document's content containing a search match, plus
/// where within [text] the match falls — Sprint 21 Task 4's
/// "highlighted match snippets".
///
/// Carries only plain data. Deciding *how* to render the highlight
/// (bold, background color, etc.) is a Presentation-layer concern, not
/// this Logic-layer service's — see [SearchService.snippetFor].
class SearchSnippet {
  const SearchSnippet({
    required this.text,
    required this.matchStart,
    required this.matchLength,
  });

  /// The excerpt itself, with a leading/trailing '…' when it's been
  /// truncated from a longer document.
  final String text;

  /// Index within [text] where the match begins.
  final int matchStart;

  /// Length of the match within [text], starting at [matchStart].
  final int matchLength;
}

/// Case-insensitive substring search across title, Markdown content,
/// and metadata — Sprint 21 Tasks 1/2.
///
/// Every method takes a [List<DocumentWithMetadata>] (Sprint 18's
/// "parse once" pairing, from [MetadataQueryService.withMetadata]) —
/// never a raw [List<Document>] that would need parsing itself. This is
/// Task 7's "avoid reparsing metadata unnecessarily" taken at face
/// value: this service has no way to reparse anything even if it
/// wanted to, because it's never handed anything unparsed.
///
/// Static and dependency-free, same shape as [MetadataQueryService] and
/// [VaultSyncService]: every method is a pure function of what's
/// handed to it.
///
/// "Fast enough for large vaults" (Task 1) here means a straightforward
/// linear scan with case-insensitive substring matching — no index,
/// no precomputed lowercase copies stored anywhere. For the vault sizes
/// this app targets (a personal note collection, not a corpus), that's
/// enough; a real inverted index would be a materially bigger
/// undertaking than "search," and isn't warranted by anything measured
/// so far. See Technical Debt.
class SearchService {
  SearchService._(); // not instantiable

  /// True if [query] appears anywhere in [document]'s title.
  static bool matchesTitle(DocumentWithMetadata document, String query) {
    return _containsCI(document.document.title, query);
  }

  /// True if [query] appears anywhere in [document]'s Markdown content
  /// (frontmatter block included — that's still just text in the file).
  static bool matchesContent(DocumentWithMetadata document, String query) {
    return _containsCI(document.document.content, query);
  }

  /// True if [query] appears in [document]'s type, any tag, or any
  /// custom frontmatter property's value.
  static bool matchesMetadata(DocumentWithMetadata document, String query) {
    final type = document.metadata.type;
    if (type != null && _containsCI(type, query)) return true;
    if (document.metadata.tags.any((tag) => _containsCI(tag, query))) {
      return true;
    }
    for (final value in document.metadata.custom.values) {
      if (_containsCI(value.toString(), query)) return true;
    }
    return false;
  }

  /// True if [query] matches [document] anywhere — title, content, or
  /// metadata. This is Task 1's "global search."
  static bool matches(DocumentWithMetadata document, String query) {
    return matchesTitle(document, query) ||
        matchesContent(document, query) ||
        matchesMetadata(document, query);
  }

  /// Every document in [documents] that [matches] [query].
  ///
  /// A blank [query] returns an empty result rather than every
  /// document — an empty search box is "nothing typed yet," not a
  /// request to see the whole vault (the existing documents list screen
  /// already does that job).
  ///
  /// Returns `List<Document>`, not `List<DocumentWithMetadata>` — same
  /// convention as every [MetadataQueryService] filter
  /// (favorites/pinned/byType/byTag): metadata is consumed internally
  /// to decide what matches, but callers just want documents back.
  static List<Document> search(
    List<DocumentWithMetadata> documents,
    String query,
  ) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return [
      for (final document in documents)
        if (matches(document, trimmed)) document.document,
    ];
  }

  /// A short excerpt of [document]'s content centered on the first
  /// case-insensitive occurrence of [query], for Task 4's "highlighted
  /// match snippets (if practical)". Returns null when [query] doesn't
  /// occur in the content at all (e.g. the match was only in the title
  /// or metadata) — the caller can fall back to showing nothing or the
  /// content's opening line in that case, rather than a misleading
  /// snippet that doesn't actually contain the match.
  ///
  /// Deliberately returns plain text, not marked-up/highlighted text —
  /// *where* the match starts within the returned snippet is exposed
  /// via [SearchSnippet.matchStart]/[SearchSnippet.matchLength] so the
  /// Presentation layer decides how to render the highlight (Text.rich,
  /// a background span, etc.). Building that widget here would put
  /// UI-shaped decisions in the Logic layer.
  static SearchSnippet? snippetFor(
    Document document,
    String query, {
    int contextChars = 40,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final content = document.content;
    final lowerContent = content.toLowerCase();
    final matchIndex = lowerContent.indexOf(trimmed.toLowerCase());
    if (matchIndex == -1) return null;

    final rawStart = matchIndex - contextChars;
    final start = rawStart < 0 ? 0 : rawStart;
    final endOfMatch = matchIndex + trimmed.length;
    final rawEnd = endOfMatch + contextChars;
    final end = rawEnd > content.length ? content.length : rawEnd;

    final prefix = start > 0 ? '…' : '';
    final suffix = end < content.length ? '…' : '';
    final excerpt = '$prefix${content.substring(start, end)}$suffix';

    return SearchSnippet(
      text: excerpt,
      matchStart: matchIndex - start + prefix.length,
      matchLength: trimmed.length,
    );
  }

  /// Every distinct tag across [documents], with how many documents
  /// carry each one, sorted alphabetically — Task 5's Tag Explorer.
  static List<TagCount> tagCounts(List<DocumentWithMetadata> documents) {
    final counts = <String, int>{};
    for (final document in documents) {
      for (final tag in document.metadata.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final result = [
      for (final entry in counts.entries) TagCount(entry.key, entry.value),
    ];
    result.sort((a, b) => a.tag.compareTo(b.tag));
    return result;
  }

  static bool _containsCI(String haystack, String needle) {
    return haystack.toLowerCase().contains(needle.toLowerCase());
  }
}
