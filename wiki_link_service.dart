import '../data/document_model.dart';

/// A single `[[...]]` reference extracted from a document's content —
/// Sprint 22 Task 1.
///
/// Carries the raw target/alias text only. Whether [target] actually
/// resolves to a document is a separate question — see
/// [WikiLinkService.resolve].
class WikiLink {
  const WikiLink({required this.target, this.alias});

  /// The text between `[[` and `|` (or `]]` if there's no alias) —
  /// e.g. `"Folder/Page"` for `[[Folder/Page|Alias]]`.
  final String target;

  /// The text between `|` and `]]`, or null when there's no `|` — e.g.
  /// `"Alias"` for `[[Folder/Page|Alias]]`, null for `[[Page]]`.
  final String? alias;

  /// What a reader would see: [alias] if present, else [target].
  String get displayText => alias ?? target;

  @override
  String toString() => alias == null ? '[[$target]]' : '[[$target|$alias]]';
}

/// A path/basename/title index over a document list, built once and
/// reused for every link resolution against that list — Sprint 22
/// Task 4's "avoid unnecessary recomputation" starts here: without
/// this, resolving N links would mean up to 3×N linear scans over every
/// document; with it, each resolution is three map lookups regardless
/// of vault size.
///
/// When two documents share a basename or title, the later one in
/// [documents] wins that slot — an accepted simplification for
/// same-named notes in different folders, the same ambiguity Obsidian
/// itself has to resolve somehow. See Technical Debt.
class DocumentIndex {
  DocumentIndex(List<Document> documents)
      : byPath = {for (final d in documents) d.path: d},
        byBasename = {for (final d in documents) _basenameKey(d.path): d},
        byTitle = {for (final d in documents) d.title.toLowerCase(): d};

  final Map<String, Document> byPath;
  final Map<String, Document> byBasename;
  final Map<String, Document> byTitle;

  /// The last path segment, lowercased, with a `.md` extension (if any)
  /// stripped — e.g. `"Folder/Page.md"` and `"page.MD"` both key to
  /// `"page"`. Manual slash/extension handling, not `package:path` —
  /// matches ObsidianDocumentRepository's own established convention
  /// (Sprint 15) for this exact kind of path handling.
  static String _basenameKey(String path) {
    final slash = path.lastIndexOf('/');
    final name = slash == -1 ? path : path.substring(slash + 1);
    final lower = name.toLowerCase();
    return lower.endsWith('.md') ? lower.substring(0, lower.length - 3) : lower;
  }
}

/// Extracts and resolves `[[wiki links]]` — Sprint 22 Tasks 1/2.
///
/// Static and dependency-free, same shape as every other service this
/// project has built (MetadataQueryService, SearchService,
/// VaultSyncService): every method is a pure function of what's handed
/// to it.
///
/// Read-only, like every text-parsing service since
/// core/utils/frontmatter_parser.dart (Sprint 15): nothing here ever
/// writes back to a document's content, so "do not alter markdown
/// formatting" (Task 1) holds by construction — there is no code path
/// that could alter it, because there is no write path here at all.
class WikiLinkService {
  WikiLinkService._(); // not instantiable

  /// Matches `[[target]]` or `[[target|alias]]`. The target and alias
  /// character classes exclude `[`, `]`, and (for the target) `|`, so
  /// this can't match across a broken/nested bracket sequence — an
  /// unclosed `[[Page` or a stray `[single]` simply won't match at all,
  /// which is Task 2's "ignores malformed links safely" at the parsing
  /// level.
  static final RegExp _pattern = RegExp(
    r'\[\[([^\[\]|]+)(?:\|([^\[\]]+))?\]\]',
  );

  /// Every wiki link in [content], in the order they appear.
  ///
  /// A link whose target is empty or whitespace-only after trimming
  /// (e.g. `[[   ]]`) is skipped — matched by the regex's character
  /// class, but not a real reference to anything, so silently dropped
  /// rather than surfaced as a document with a nonsense outgoing link.
  /// A whitespace-only alias (e.g. `[[Page| ]]` — a truly empty one
  /// like `[[Page|]]` doesn't match the pattern at all, verified
  /// empirically rather than assumed) is treated as no alias, not an
  /// alias of literal whitespace.
  static List<WikiLink> extractLinks(String content) {
    final results = <WikiLink>[];
    for (final match in _pattern.allMatches(content)) {
      final target = match.group(1)!.trim();
      if (target.isEmpty) continue;
      final rawAlias = match.group(2)?.trim();
      final alias = (rawAlias == null || rawAlias.isEmpty) ? null : rawAlias;
      results.add(WikiLink(target: target, alias: alias));
    }
    return results;
  }

  /// Resolves [link]'s target against [index], or null if nothing
  /// matches — a broken link, which the caller (see
  /// backlink_engine.dart) reports rather than treats as an error.
  ///
  /// Tries, in order:
  /// 1. Exact path match (`[[Folder/Page]]` against a document literally
  ///    at `Folder/Page.md`) — the most specific, least ambiguous case.
  /// 2. Basename match, case-insensitive (`[[Page]]` against a document
  ///    named `Page.md` anywhere in the vault) — mirrors how Obsidian
  ///    itself resolves a bare note name.
  /// 3. Title match, case-insensitive — a fallback for internal-vault
  ///    documents, where the path is often a generated id rather than a
  ///    human-chosen name, so path/basename matching alone would miss
  ///    them even when a title-based reference is exactly what a user
  ///    typing `[[My Note]]` means.
  static Document? resolve(WikiLink link, DocumentIndex index) {
    final target = link.target;
    final targetPath =
        target.toLowerCase().endsWith('.md') ? target : '$target.md';

    final byPath = index.byPath[targetPath];
    if (byPath != null) return byPath;

    final byBasename =
        index.byBasename[DocumentIndex._basenameKey(targetPath)];
    if (byBasename != null) return byBasename;

    return index.byTitle[target.toLowerCase()];
  }
}
