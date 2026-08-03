import 'vault_model.dart';

/// An immutable snapshot of a markdown document from any vault.
///
/// [vaultId] ties each document to its [Vault] — replacing the old
/// [DocumentSource] enum. Consumers ask [VaultRepository] for the
/// corresponding [Vault] when they need type-level metadata; they
/// never switch on storage type themselves.
///
/// Pure Dart — no Flutter or Riverpod imports.
class Document {
  const Document({
    required this.path,
    required this.title,
    required this.content,
    required this.vaultId,
    required this.createdAt,
    required this.updatedAt,
    this.frontmatter = const {},
    this.tags = const [],
    this.backlinks = const [],
    this.metadata = const {},
  });

  /// Relative path within the vault root, e.g. `daily/2025-07-11.md`.
  final String path;

  final String title;

  /// Raw markdown — never parsed at the model layer.
  final String content;

  /// The [Vault.id] this document belongs to. Use [VaultRepository]
  /// to resolve the full [Vault] when needed.
  final String vaultId;

  /// YAML frontmatter parsed into a map by the adapter.
  final Map<String, dynamic> frontmatter;

  /// Derived from frontmatter; stored separately for fast filtering.
  final List<String> tags;

  /// Paths of other documents that link to this one.
  final List<String> backlinks;

  /// Adapter-specific extra data (Drive ID, vault root, etc.).
  final Map<String, dynamic> metadata;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => content.trim().isEmpty;

  Document copyWith({
    String? title,
    String? content,
    List<String>? tags,
    List<String>? backlinks,
    Map<String, dynamic>? frontmatter,
    Map<String, dynamic>? metadata,
  }) {
    return Document(
      path: path,
      vaultId: vaultId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      title: title ?? this.title,
      content: content ?? this.content,
      frontmatter: frontmatter ?? this.frontmatter,
      tags: tags ?? this.tags,
      backlinks: backlinks ?? this.backlinks,
      metadata: metadata ?? this.metadata,
    );
  }
}
