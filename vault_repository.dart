import 'vault_model.dart';

/// Manages the set of configured [Vault]s and the currently active one.
///
/// Separating vault management from document CRUD keeps [DocumentRepository]
/// focused. Neither class knows about the other — the provider layer
/// composes them:
///
/// ```
/// VaultRepository          DocumentRepository
///   getActive() → Vault  →  (scoped to that vault)
/// ```
///
/// Implementations will persist vault configuration to SQLite or
/// SharedPreferences. Deferred to the Settings / Internal Documents sprint.
abstract class VaultRepository {
  /// All vaults the user has configured.
  Future<List<Vault>> getAll();

  /// The vault currently selected by the user, or null if none yet.
  Future<Vault?> getActive();

  /// Switches the active vault. [vaultId] must exist in [getAll()].
  Future<void> setActive(String vaultId);

  /// Registers a new vault. Persists it for future app launches.
  Future<void> addVault(Vault vault);

  /// Removes a vault by id. Does NOT delete documents inside it.
  Future<void> removeVault(String vaultId);
}
