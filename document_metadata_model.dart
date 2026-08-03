import '../../../core/utils/frontmatter_parser.dart';

/// A typed, structured view of a [Document]'s YAML frontmatter.
///
/// **Not to be confused with `Document.metadata`** (in document_model.dart)
/// — that field is adapter-internal bookkeeping (a Google Drive file ID,
/// an Obsidian vault root, etc.) and has nothing to do with this class.
/// This class is the Sprint 17 "Metadata Foundation": the frontmatter
/// properties (`title`, `type`, `tags`, `favorite`, `pinned`, `created`,
/// `modified`, plus anything else the user writes) that future features —
/// Journal, Favorites, Projects, Study Notes — will key off of instead of
/// each inventing its own document flavour.
///
/// Always constructed via [DocumentMetadata.fromFrontmatter] — see
/// [DocumentMetadataService] (document_metadata_service.dart) for how a
/// [Document] becomes a parsed frontmatter map in the first place.
///
/// Pure Dart — no Flutter import.
class DocumentMetadata {
  const DocumentMetadata({
    required this.title,
    this.type,
    this.tags = const [],
    this.favorite = false,
    this.pinned = false,
    required this.created,
    required this.modified,
    this.custom = const {},
  });

  /// From frontmatter's `title:` if present and a string, else the
  /// document's own [Document.title] — a document always has *some*
  /// title, so this field is never null.
  final String title;

  /// Frontmatter's `type:` (e.g. `"journal"`, `"project"`), or null when
  /// absent. Deliberately a bare string, not an enum — per this sprint's
  /// whole premise, document "types" are metadata, not separate classes,
  /// so new types never require a code change here.
  final String? type;

  /// From frontmatter's `tags:`. Empty when absent or malformed.
  final List<String> tags;

  /// From frontmatter's `favorite:`. Defaults to `false` — absent, wrong
  /// type (e.g. a quoted `"true"` string), or malformed all degrade to
  /// "not a favorite" rather than throwing.
  final bool favorite;

  /// From frontmatter's `pinned:`. Same defaulting rule as [favorite].
  final bool pinned;

  /// From frontmatter's `created:` when present and a valid date,
  /// else [Document.createdAt]. Never null — a document always has a
  /// creation time from the repository, frontmatter or not.
  final DateTime created;

  /// From frontmatter's `modified:` when present and a valid date,
  /// else [Document.updatedAt]. Same reasoning as [created].
  final DateTime modified;

  /// Every other frontmatter key, untouched. This is what makes
  /// "custom properties" work: a user (or a future feature) can put
  /// anything in frontmatter — `mood: happy`, `project: LifeOS`,
  /// `rating: 5` — and it survives here even though this class has no
  /// field named for it.
  final Map<String, dynamic> custom;

  static const List<String> _knownKeys = [
    'title',
    'type',
    'tags',
    'favorite',
    'pinned',
    'created',
    'modified',
  ];

  /// Builds a [DocumentMetadata] from an already-parsed frontmatter map
  /// (see `parseFrontmatter` in core/utils/frontmatter_parser.dart) plus
  /// the owning document's own title/timestamps to fall back on.
  ///
  /// [frontmatter] may be `const {}` (no frontmatter block, or a
  /// malformed one that [parseFrontmatter] already degraded to empty) —
  /// every field below has a defined fallback for that case, so this
  /// factory never throws and never needs its caller to branch on
  /// whether frontmatter existed.
  factory DocumentMetadata.fromFrontmatter(
    Map<String, dynamic> frontmatter, {
    required String fallbackTitle,
    required DateTime fallbackCreated,
    required DateTime fallbackModified,
  }) {
    final rawTitle = frontmatter['title'];
    final title = (rawTitle is String && rawTitle.trim().isNotEmpty)
        ? rawTitle
        : fallbackTitle;

    final rawType = frontmatter['type'];
    final type = (rawType is String && rawType.trim().isNotEmpty)
        ? rawType
        : null;

    final custom = Map<String, dynamic>.fromEntries(
      frontmatter.entries.where((e) => !_knownKeys.contains(e.key)),
    );

    return DocumentMetadata(
      title: title,
      type: type,
      tags: tagsFromFrontmatter(frontmatter),
      favorite: frontmatter['favorite'] == true,
      pinned: frontmatter['pinned'] == true,
      created: _parseDate(frontmatter['created']) ?? fallbackCreated,
      modified: _parseDate(frontmatter['modified']) ?? fallbackModified,
      custom: custom,
    );
  }

  /// Accepts a [DateTime] directly — the `yaml` package already parses
  /// an unquoted ISO date scalar (`created: 2026-01-15`) into one — or a
  /// string it can parse itself (`created: "2026-01-15"`). Anything else
  /// (wrong type, unparsable string, missing key) returns null so the
  /// caller's fallback applies.
  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
