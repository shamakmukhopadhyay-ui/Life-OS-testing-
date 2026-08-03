import '../data/vault_model.dart';
import '../data/vault_repository.dart';

/// A minimal [VaultRepository] that always exposes [Vault.defaultInternal]
/// as the sole, active vault.
///
/// Used in [main] to bootstrap the document layer without requiring a
/// Settings screen or vault configuration UI. When vault switching is
/// introduced, this class is replaced by a SQLite-backed implementation
/// that persists the user's vault list and active selection.
class DefaultVaultRepository implements VaultRepository {
  const DefaultVaultRepository();

  @override
  Future<List<Vault>> getAll() async => const [Vault.defaultInternal];

  @override
  Future<Vault?> getActive() async => Vault.defaultInternal;

  /// No-op — only one vault is supported at this stage.
  @override
  Future<void> setActive(String vaultId) async {}

  /// No-op — vault list is hard-wired.
  @override
  Future<void> addVault(Vault vault) async {}

  /// No-op — vault list is hard-wired.
  @override
  Future<void> removeVault(String vaultId) async {}
}
