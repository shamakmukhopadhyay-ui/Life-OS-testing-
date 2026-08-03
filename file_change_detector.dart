import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_model.dart';

/// Detects whether a document's content has changed since LifeOS last
/// knew about it — the "lightweight mechanism" Sprint 19 Task 2 asks
/// for, deliberately on-demand rather than continuous.
///
/// This is *detection*, not *watching*: nothing here polls, listens, or
/// runs on a timer. Something else has to call [hasChangedSinceRecorded]
/// — right now, nothing does (see [VaultSyncService] in
/// vault_sync_service.dart for the one caller this sprint adds, itself
/// not wired to any automatic trigger yet). That's the explicit scope
/// boundary: "design it so future sync can build upon it" without
/// "implement continuous background watching yet."
///
/// ## Why a content fingerprint, not file mtime
///
/// The natural alternative — compare the file's OS-level modification
/// time — was considered and rejected for this foundation:
/// [FileSystemService] has no stat/mtime accessor (a known limitation
/// since Sprint 15's Technical Debt), and mtime is unreliable across
/// sync tools anyway (some don't preserve it faithfully). A fingerprint
/// of the content this class already has in hand needs no new
/// filesystem primitive and answers the question that actually matters
/// — did the bytes change — directly.
///
/// ## Why hashCode, not a cryptographic hash
///
/// [String.hashCode] is deterministic within one running Dart VM
/// instance, which is exactly what's needed: this registry is in-memory
/// only, rebuilt fresh every app launch, and never persisted or compared
/// across separate runs. A `package:crypto` hash would be no more
/// correct for that scope and would be a new dependency this sprint
/// doesn't need.
class FileChangeDetector {
  final Map<String, int> _knownFingerprints = {};

  static int _fingerprintOf(String content) => content.hashCode;

  /// Records [document]'s current content as the known baseline for its
  /// path. Call this after reading or saving a document through
  /// LifeOS's normal flow, so a later external edit can be told apart
  /// from a change LifeOS made itself.
  void recordKnownState(Document document) {
    _knownFingerprints[document.path] = _fingerprintOf(document.content);
  }

  /// Whether a baseline has been recorded yet for [path]. Distinguishing
  /// "never seen before" from "seen and unchanged" matters: a document
  /// LifeOS has never recorded isn't "changed," it's just unknown, and
  /// [hasChangedSinceRecorded] treats it accordingly.
  bool hasBaseline(String path) => _knownFingerprints.containsKey(path);

  /// True only when a baseline exists for [document]'s path *and* its
  /// current content's fingerprint differs from that baseline. Returns
  /// false — not true — when there is no baseline at all, since that's
  /// a distinct state ("unknown") from "known and different." Callers
  /// that need to tell those two apart should check [hasBaseline] first.
  bool hasChangedSinceRecorded(Document document) {
    final known = _knownFingerprints[document.path];
    if (known == null) return false;
    return known != _fingerprintOf(document.content);
  }

  /// Removes any recorded baseline for [path] — e.g. after a document
  /// is deleted, so a future path reusing the same string doesn't
  /// inherit a stale fingerprint.
  void forget(String path) => _knownFingerprints.remove(path);

  /// Clears every recorded baseline. Mainly for tests, and for a
  /// possible future "re-sync everything from scratch" action.
  void reset() => _knownFingerprints.clear();

  /// Number of paths with a recorded baseline. Exposed for tests/
  /// debugging, not used by any UI.
  int get knownPathCount => _knownFingerprints.length;
}

/// A single, app-lifetime-shared [FileChangeDetector] instance.
///
/// Deliberately *not* `.autoDispose` — unlike Sprint 17/18's derived
/// providers, this one exists specifically to remember state across
/// separate calls over time. Disposing it the moment nothing watches it
/// would defeat its entire purpose.
final fileChangeDetectorProvider = Provider<FileChangeDetector>((ref) {
  return FileChangeDetector();
});
