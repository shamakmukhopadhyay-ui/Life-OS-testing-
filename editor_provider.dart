import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_model.dart';
import '../data/document_repository.dart';
import 'document_provider.dart';

/// Contains the business logic for editing a [Document].
///
/// Lives in the Logic layer — no Flutter imports. Handles the only
/// non-trivial editing rule: skip the DB write when nothing changed.
class DocumentEditorService {
  const DocumentEditorService(this._repo);

  final DocumentRepository _repo;

  /// Persists [title] and [content] only when they differ from [current].
  ///
  /// Returns the saved document (with updated [Document.updatedAt]) on
  /// write, or [current] unchanged when nothing was dirty. This prevents
  /// redundant SQLite writes when the debounce fires after an idle period
  /// or when [dispose] calls save after a prior successful autosave.
  Future<Document> saveIfChanged({
    required Document current,
    required String title,
    required String content,
  }) async {
    final cleanTitle = title.trim().isEmpty ? current.title : title.trim();
    if (current.content == content && current.title == cleanTitle) {
      return current;
    }
    final updated = current.copyWith(title: cleanTitle, content: content);
    return _repo.save(updated);
  }
}

/// [DocumentEditorService] wired to the active vault's [DocumentRepository].
/// AutoDispose so it is released when the editor screen is gone.
final documentEditorServiceProvider =
    Provider.autoDispose<DocumentEditorService>((ref) {
  return DocumentEditorService(ref.read(documentRepositoryProvider));
});
