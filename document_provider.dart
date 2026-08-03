import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/filesystem/filesystem_service.dart';
import '../data/document_model.dart';
import '../data/document_repository.dart';
import '../data/internal_document_repository.dart';
import '../data/obsidian_document_repository.dart';
import '../data/vault_model.dart';
import '../data/vault_repository.dart';
import 'daily_note_service.dart';

/// The vault manager — throws until wired in the Settings sprint.
/// Override in ProviderScope once a VaultRepository is implemented.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  throw UnimplementedError(
    'vaultRepositoryProvider has no registered implementation.',
  );
});

/// The currently active [Vault], or null if none configured.
/// Gracefully returns null when [vaultRepositoryProvider] is unregistered.
final activeVaultProvider = FutureProvider<Vault?>((ref) async {
  try {
    return ref.read(vaultRepositoryProvider).getActive();
  } on UnimplementedError {
    return null;
  }
});

/// A [DocumentRepository] scoped to the active vault.
///
/// Dispatches to the correct adapter based on [Vault.type].
/// Consumers never import an adapter class — they only see this provider.
/// Throws when no vault is active yet.
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final vault = ref.watch(activeVaultProvider).valueOrNull;
  if (vault == null) {
    throw UnimplementedError(
      'No active vault. Configure one in Settings to enable documents.',
    );
  }
  return switch (vault.type) {
    VaultType.internal => InternalDocumentRepository(
        vault: vault,
        db: ref.read(databaseProvider),
      ),
    VaultType.obsidian => ObsidianDocumentRepository(
        vault: vault,
        fileSystem: ref.read(fileSystemServiceProvider),
      ),
    VaultType.googleDrive =>
      throw UnimplementedError('Google Drive vault not yet implemented'),
  };
});

/// Daily note for the given date, from the active vault — auto-created if it
/// doesn't exist yet (Sprint 23 Task 1: uses [DailyNoteService.getOrCreate],
/// not just `.get`, so opening any date always yields a real document).
/// Null only when no vault is configured at all, matching this
/// provider's existing contract for that case.
final dailyNoteProvider =
    FutureProvider.family<Document?, DateTime>((ref, date) async {
  final vault = ref.watch(activeVaultProvider).valueOrNull;
  if (vault == null) return null;
  try {
    final repo = ref.read(documentRepositoryProvider);
    return await DailyNoteService.getOrCreate(repo, date, vault);
  } on UnimplementedError {
    return null;
  }
});
