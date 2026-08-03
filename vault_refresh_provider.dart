import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'documents_list_provider.dart';
import 'file_change_detector.dart';
import 'vault_sync_service.dart';

/// The outcome of the most recent manual vault refresh — Sprint 20
/// Tasks 1/2.
class VaultRefreshStatus {
  const VaultRefreshStatus({
    required this.completedAt,
    required this.changedFilePaths,
  });

  /// When this refresh finished.
  final DateTime completedAt;

  /// Paths [VaultSyncService] identified as changed since the
  /// *previous* baseline. Empty on the very first refresh in a session
  /// — there's nothing to compare against yet — which is a correct
  /// "0 changed," not a failure.
  final List<String> changedFilePaths;
}

/// Drives Sprint 20's manual refresh action.
///
/// Starts as `null` — no refresh has happened yet this session, which
/// the Vault Status screen shows as "never refreshed" rather than a
/// stale default. Nothing calls [refreshNow] automatically ("no
/// automatic background sync," "no file watching" — this sprint's own
/// constraints), so `null` can persist indefinitely until the user
/// taps the refresh action.
class VaultRefreshNotifier extends AsyncNotifier<VaultRefreshStatus?> {
  @override
  Future<VaultRefreshStatus?> build() async => null;

  /// Re-fetches every document, then reports which of them actually
  /// changed since the last refresh (or since app launch, for the
  /// first one).
  ///
  /// ## "Re-index only changed files" — what that means today
  ///
  /// `DocumentRepository.getAll()` (an interface this sprint must not
  /// change) has no "only what changed" variant, so the underlying file
  /// read is unavoidably a full scan — [DocumentsNotifier.refresh] is
  /// reused as-is rather than duplicated, per "reuse existing
  /// repositories and providers." What *is* selective is everything
  /// downstream of that read: [VaultSyncService.findFilesNeedingReindex]
  /// determines which of the freshly-read documents actually changed,
  /// so a future "re-indexing" step with real work to do per document
  /// (once one exists) only needs to touch that subset, not every
  /// document. That distinction — the fetch is full, what happens with
  /// the result is targeted — is the honest scope of "only changed
  /// files" given the current repository interface.
  Future<void> refreshNow() async {
    state = await AsyncValue.guard(() async {
      final detector = ref.read(fileChangeDetectorProvider);

      await ref.read(documentsProvider.notifier).refresh();
      final fresh = ref.read(documentsProvider).valueOrNull ?? const [];

      final changed = VaultSyncService.findFilesNeedingReindex(
        fresh,
        detector,
      );
      VaultSyncService.recordBaseline(fresh, detector);

      return VaultRefreshStatus(
        completedAt: DateTime.now(),
        changedFilePaths: changed,
      );
    });
  }
}

final vaultRefreshProvider =
    AsyncNotifierProvider<VaultRefreshNotifier, VaultRefreshStatus?>(
  VaultRefreshNotifier.new,
);
