import '../data/document_model.dart';
import 'file_change_detector.dart';

/// Determines which documents need re-indexing after an external
/// modification — Sprint 19 Task 6.
///
/// Static and dependency-free, like [MetadataQueryService]
/// (metadata_query_service.dart): every method is a pure function of
/// the [FileChangeDetector] and document list handed to it. Nothing
/// here calls a repository, runs on a timer, or is wired to any screen
/// — "no UI changes" and "no automatic sync yet" are structural
/// properties of this file, not just descriptions of it: there is no
/// code path anywhere in this sprint that calls these methods
/// automatically.
///
/// Intended usage, for whenever a future sprint wires this up:
/// 1. After a full document read (e.g. `documentRepository.getAll()`),
///    call [recordBaseline] once to establish "this is what LifeOS
///    currently knows."
/// 2. Later — after switching back to the app, or on a manual refresh —
///    read again and call [findFilesNeedingReindex] with the fresh
///    list to see what changed outside LifeOS since step 1.
/// 3. After handling whatever "re-indexing" turns out to mean (a later
///    sprint's concern), call [recordBaseline] again to move the
///    baseline forward.
class VaultSyncService {
  VaultSyncService._(); // not instantiable

  /// Paths whose current content differs from [detector]'s recorded
  /// baseline. A document with no baseline yet is not included — it's
  /// unknown, not "changed" — matching
  /// [FileChangeDetector.hasChangedSinceRecorded]'s own contract.
  static List<String> findFilesNeedingReindex(
    List<Document> currentDocuments,
    FileChangeDetector detector,
  ) {
    return [
      for (final doc in currentDocuments)
        if (detector.hasBaseline(doc.path) &&
            detector.hasChangedSinceRecorded(doc))
          doc.path,
    ];
  }

  /// Records every document in [currentDocuments] as [detector]'s new
  /// baseline — a bulk convenience over
  /// [FileChangeDetector.recordKnownState] for "do this across the
  /// whole vault" callers.
  static void recordBaseline(
    List<Document> currentDocuments,
    FileChangeDetector detector,
  ) {
    for (final doc in currentDocuments) {
      detector.recordKnownState(doc);
    }
  }
}
