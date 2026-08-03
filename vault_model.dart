/// Vault model — replaces the [DocumentSource] enum.
///
/// A [Vault] is a named, typed document store. The rest of the app
/// interacts with a [DocumentRepository] scoped to a vault and never
/// needs to know which type is active.
library;

/// Discriminates the underlying storage mechanism.
/// Used internally by [documentRepositoryProvider] to instantiate the
/// correct adapter. Consumers should never switch on this.
enum VaultType { internal, obsidian, googleDrive }

/// Declares what a vault can do. The UI uses this to show/hide actions
/// (e.g. hide "Edit" for a read-only vault) without importing any
/// adapter class.
enum VaultCapability {
  read,
  write,
  search,
  backlinks,  // wiki-link graph traversal
  aiIndex,    // eligible for semantic / NotebookLM-style indexing
  sync,       // external sync capable
}

/// Represents one document store available to LifeOS.
///
/// ## Design rationale over [DocumentSource]
///
/// [DocumentSource] was an enum — it encoded *what kind* of store but
/// carried no instance-level data (path, name, capabilities). That
/// worked when only one store existed, but breaks when users configure
/// multiple Obsidian vaults or add Google Drive.
///
/// [Vault] is a proper entity: each configured store is a distinct
/// [Vault] instance with its own [id], [rootPath], and [capabilities].
/// [DocumentRepository] operates within one vault; [VaultRepository]
/// manages the set of all vaults and tracks the active one.
class Vault {
  const Vault({
    required this.id,
    required this.name,
    required this.type,
    required this.rootPath,
    this.capabilities = const {VaultCapability.read},
  });

  /// Unique identifier. For [VaultType.internal], use a fixed constant
  /// (e.g. `'internal'`). For user-added vaults, use a UUID.
  final String id;

  /// Human-readable display name (e.g. "My Obsidian Vault").
  final String name;

  final VaultType type;

  /// Absolute path to the vault root on the local filesystem.
  /// For [VaultType.internal], derived from the platform documents dir.
  /// For [VaultType.obsidian], user-configured in Settings.
  final String rootPath;

  /// What this vault supports. Checked by UI before showing actions.
  final Set<VaultCapability> capabilities;

  bool get isReadOnly => !capabilities.contains(VaultCapability.write);

  bool supports(VaultCapability capability) =>
      capabilities.contains(capability);

  /// The default internal vault used before any user configuration.
  static const defaultInternal = Vault(
    id: 'internal',
    name: 'LifeOS Notes',
    type: VaultType.internal,
    rootPath: '', // resolved at runtime from platform documents dir
    capabilities: {VaultCapability.read, VaultCapability.write, VaultCapability.search},
  );
}
