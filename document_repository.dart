import 'document_model.dart';

/// The sole abstraction all document consumers depend on.
///
/// No widget, provider, or service outside [features/documents/]
/// imports a concrete repository class. Source switching is done by
/// overriding [documentRepositoryProvider] — callers are unaffected.
///
/// Every method is async because at least one implementation (Obsidian)
/// performs filesystem I/O. Internal and cloud implementations follow
/// the same contract without requiring callers to distinguish them.
abstract class DocumentRepository {
  /// Returns the document at [path], or null if it does not exist.
  Future<Document?> getByPath(String path);

  /// Full-text search across all documents in this source.
  /// Implementations may search title, content, and tags.
  Future<List<Document>> search(String query);

  /// Returns every document available in this source.
  /// Callers should prefer [search] or [getByTag] for large vaults.
  Future<List<Document>> getAll();

  /// Returns all documents tagged with [tag].
  Future<List<Document>> getByTag(String tag);

  /// Creates or replaces [document] identified by [document.path].
  /// Returns the saved document (with updated [updatedAt]).
  Future<Document> save(Document document);

  /// Permanently removes the document at [path].
  Future<void> delete(String path);

  /// Returns true if a document exists at [path].
  Future<bool> exists(String path);
}
