import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_generator.dart';
import '../data/document_model.dart';
import '../data/document_repository.dart';
import 'document_provider.dart';

/// Business logic for renaming and duplicating a [Document].
///
/// Lives in the Logic layer — no Flutter imports. Sits alongside
/// [DocumentEditorService] (editor_provider.dart) as a second, small
/// service for the same repository: that one handles in-place edits,
/// this one handles the two "management" actions from Sprint 16.
///
/// Deletion deliberately has no method here — Sprint 16 specifies
/// deletion goes straight through the repository ("Repository performs
/// deletion"), so [DocumentsNotifier] calls `DocumentRepository.delete`
/// directly rather than through this service.
class DocumentManagementService {
  const DocumentManagementService(this._repo);

  final DocumentRepository _repo;

  static const _duplicateSuffix = ' (Copy)';

  /// Renames the document at [path] to [newTitle].
  ///
  /// Only [Document.title] changes — [path] (the document's identity
  /// across both the internal and Obsidian repositories) is never
  /// touched, so this can never collide with another document or break
  /// anything that references the original path. Skips the write and
  /// returns [current] unchanged when [newTitle] is blank or identical
  /// to the current title, matching the "don't write when nothing
  /// changed" convention already used by [DocumentEditorService].
  ///
  /// Throws [ArgumentError] if no document exists at [path].
  ///
  /// Known limitation: for an Obsidian-backed document whose file has
  /// its own `title:` frontmatter field, only [Document.title] (the
  /// parsed, in-app value) is updated — [save] never rewrites a file's
  /// content, only the frontmatter parser's read-side output. A later
  /// re-read of that file will re-derive the OLD title from disk. See
  /// Sprint 16 Technical Debt. This does not affect internal-vault
  /// documents, where title is its own independent, correctly-updated
  /// column.
  Future<Document> rename(String path, String newTitle) async {
    final current = await _repo.getByPath(path);
    if (current == null) {
      throw ArgumentError('Cannot rename: no document at "$path"');
    }
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty || cleanTitle == current.title) {
      return current;
    }
    return _repo.save(current.copyWith(title: cleanTitle));
  }

  /// Creates a copy of the document at [path] under a new path, with
  /// "(Copy)" appended to the title (unless it's already there, so
  /// duplicating a duplicate doesn't stack suffixes).
  ///
  /// The new path lives in the same folder as the original (e.g.
  /// duplicating `notes/Ideas.md` produces `notes/<id>.md`), using
  /// [generateLocalId] for a collision-safe filename — the same
  /// generator already used for Objective/Task ids.
  ///
  /// [backlinks] is reset to empty on the copy: other documents link to
  /// the *original's* path, not the new one, so carrying the original's
  /// backlinks over would misrepresent what actually links to the copy.
  ///
  /// Throws [ArgumentError] if no document exists at [path].
  ///
  /// Same known limitation as [rename]: the copy's markdown content
  /// (for Obsidian) still carries the original's frontmatter title, if
  /// any, verbatim.
  Future<Document> duplicate(String path) async {
    final original = await _repo.getByPath(path);
    if (original == null) {
      throw ArgumentError('Cannot duplicate: no document at "$path"');
    }
    final now = DateTime.now();
    final copy = Document(
      path: '${_directoryOf(path)}${generateLocalId()}.md',
      vaultId: original.vaultId,
      title: _titleForDuplicate(original.title),
      content: original.content,
      frontmatter: original.frontmatter,
      tags: original.tags,
      metadata: original.metadata,
      createdAt: now,
      updatedAt: now,
    );
    return _repo.save(copy);
  }

  /// The portion of [path] up to and including the last `/`, or `''`
  /// for a top-level path. Deliberately manual (no `package:path`) to
  /// match ObsidianDocumentRepository's existing convention of not
  /// pulling that package into this kind of path handling.
  String _directoryOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash == -1 ? '' : path.substring(0, slash + 1);
  }

  String _titleForDuplicate(String originalTitle) {
    return originalTitle.endsWith(_duplicateSuffix)
        ? originalTitle
        : '$originalTitle$_duplicateSuffix';
  }
}

/// [DocumentManagementService] wired to the active vault's
/// [DocumentRepository] — same wiring pattern as
/// `documentEditorServiceProvider` in editor_provider.dart.
final documentManagementServiceProvider =
    Provider<DocumentManagementService>((ref) {
  return DocumentManagementService(ref.read(documentRepositoryProvider));
});
