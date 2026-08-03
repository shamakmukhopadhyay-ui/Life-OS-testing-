import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_model.dart';
import 'document_management_service.dart';
import 'document_provider.dart';

/// Holds every document in the active vault, and every mutation that can
/// change that list: create, rename, duplicate, delete.
///
/// Sprint 16. Follows the exact same pattern as ObjectivesNotifier
/// (objectives_provider.dart): every method writes through the
/// repository or service first, then reloads the full list from source —
/// state is never patched optimistically in memory. This keeps this
/// list consistent with whatever InternalDocumentRepository/
/// ObsidianDocumentRepository actually persisted, the same reasoning
/// ObjectivesNotifier's own doc comment gives.
class DocumentsNotifier extends AsyncNotifier<List<Document>> {
  @override
  Future<List<Document>> build() => _load();

  /// Loads the full list and sorts it most-recently-edited first.
  ///
  /// Worth doing here rather than in either repository:
  /// InternalDocumentRepository.getAll() already orders by
  /// `updated_at DESC` in SQL, but ObsidianDocumentRepository.getAll()
  /// returns whatever order its directory walk happens to encounter
  /// files in — no sort guarantee at all. Sorting once here gives a
  /// consistent list UX regardless of which repository is active,
  /// without touching either repository's approved Sprint 15/pre-15
  /// code. Flagged in Sprint 16 Technical Debt as a repository-level
  /// inconsistency, fixed at this layer instead.
  Future<List<Document>> _load() async {
    final docs = await ref.read(documentRepositoryProvider).getAll();
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  /// Re-runs the load without any preceding write.
  ///
  /// Every other list in this app (Objectives, Tasks) only ever changes
  /// through its own mutation methods, so a manual refresh was never
  /// needed for them. Documents are different: an Obsidian-backed vault
  /// can change on disk from outside the app entirely (Obsidian itself,
  /// or a sync tool) with no filesystem watcher to notice — see
  /// ObsidianDocumentRepository's Sprint 15 Technical Debt. This is what
  /// DocumentsListScreen's pull-to-refresh calls.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> createDocument(Document document) async {
    await ref.read(documentRepositoryProvider).save(document);
    state = await AsyncValue.guard(_load);
  }

  Future<void> renameDocument(String path, String newTitle) async {
    await ref.read(documentManagementServiceProvider).rename(path, newTitle);
    state = await AsyncValue.guard(_load);
  }

  Future<void> duplicateDocument(String path) async {
    await ref.read(documentManagementServiceProvider).duplicate(path);
    state = await AsyncValue.guard(_load);
  }

  /// Deletes via the repository directly, per Sprint 16 Task 2
  /// ("Repository performs deletion") — unlike rename/duplicate, this
  /// doesn't go through DocumentManagementService.
  Future<void> deleteDocument(String path) async {
    await ref.read(documentRepositoryProvider).delete(path);
    state = await AsyncValue.guard(_load);
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<Document>>(
  DocumentsNotifier.new,
);
