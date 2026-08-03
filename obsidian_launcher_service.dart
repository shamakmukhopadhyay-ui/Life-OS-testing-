import '../data/document_model.dart';
import '../data/vault_model.dart';

/// What happened when [ObsidianLauncherService.buildLaunchRequest] was
/// asked to open a document in Obsidian.
enum ObsidianLaunchOutcome {
  /// No vault is active at all — Task 4's "missing vault".
  noActiveVault,

  /// The document's active vault isn't an Obsidian vault, so there's
  /// nothing on disk for Obsidian to open (an internal-vault document
  /// only exists as a SQLite row).
  notAnObsidianVault,

  /// The `obsidian://` URI was built correctly, but this sprint has no
  /// way to hand it to the OS — see [ObsidianLauncherService]'s class
  /// doc. Task 4's "Obsidian unavailable", reported honestly rather
  /// than silently doing nothing or claiming success.
  launchUnavailable,
}

/// Result of a single open-in-Obsidian attempt.
class ObsidianLaunchResult {
  const ObsidianLaunchResult({required this.outcome, this.uri});

  final ObsidianLaunchOutcome outcome;

  /// The `obsidian://` URI that was (or would be) opened — present only
  /// when [outcome] is [ObsidianLaunchOutcome.launchUnavailable], so a
  /// fallback UI has something concrete to show or offer to copy.
  final String? uri;
}

/// Builds an `obsidian://open` request for a [Document] — Sprint 20
/// Task 3's "platform abstraction/service responsible for opening the
/// current document in Obsidian."
///
/// ## Why this can't actually launch anything yet
///
/// Handing a URI to the OS to open another app needs either a launch
/// plugin (commonly `url_launcher`) or a platform channel. This sprint
/// adds neither: "no new packages unless absolutely necessary," and a
/// platform channel is a materially bigger undertaking than this one
/// action. Task 3 explicitly anticipates exactly this: "if platform
/// integration is not yet possible, provide the service interface and
/// graceful fallback." That's this class's whole shape — the request is
/// always correctly built, [ObsidianLaunchResult.outcome] always
/// truthfully reports [ObsidianLaunchOutcome.launchUnavailable] rather
/// than pretending to have opened anything, and a future sprint that
/// adds a real launch mechanism only has to change what happens with
/// the built [ObsidianLaunchResult.uri] — not how it's constructed.
///
/// Static and dependency-free, same reasoning as [MetadataQueryService]
/// and [VaultSyncService]: every method is a pure function of what's
/// handed to it.
///
/// ## URI format
///
/// Verified against Obsidian's own documentation
/// (help.obsidian.md/Extending+Obsidian/Obsidian+URI) rather than
/// assumed: `obsidian://open?vault=<name>&file=<path>`, both values
/// percent-encoded (forward slashes and spaces included), and the
/// `.md` extension omitted from `file`.
class ObsidianLauncherService {
  ObsidianLauncherService._(); // not instantiable

  static ObsidianLaunchResult buildLaunchRequest({
    required Document document,
    required Vault? vault,
  }) {
    if (vault == null) {
      return const ObsidianLaunchResult(
        outcome: ObsidianLaunchOutcome.noActiveVault,
      );
    }
    if (vault.type != VaultType.obsidian) {
      return const ObsidianLaunchResult(
        outcome: ObsidianLaunchOutcome.notAnObsidianVault,
      );
    }
    return ObsidianLaunchResult(
      outcome: ObsidianLaunchOutcome.launchUnavailable,
      uri: _buildUri(vaultName: vault.name, filePath: document.path),
    );
  }

  static String _buildUri({
    required String vaultName,
    required String filePath,
  }) {
    final withoutExtension = filePath.toLowerCase().endsWith('.md')
        ? filePath.substring(0, filePath.length - 3)
        : filePath;
    // Uri.encodeComponent, not Uri.encodeQueryComponent: the latter
    // follows the HTML-form convention of encoding a space as '+', but
    // Obsidian's own documentation explicitly requires '%20' — using
    // the query-form encoder here would build a URI Obsidian doesn't
    // actually document supporting.
    final encodedVault = Uri.encodeComponent(vaultName);
    final encodedFile = Uri.encodeComponent(withoutExtension);
    return 'obsidian://open?vault=$encodedVault&file=$encodedFile';
  }
}
