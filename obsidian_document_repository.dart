import '../../../core/filesystem/filesystem_service.dart';
import '../../../core/utils/frontmatter_parser.dart';
import 'document_model.dart';
import 'document_repository.dart';
import 'vault_model.dart';

/// Reads and writes documents from an Obsidian vault via [FileSystemService].
///
/// [fileSystem] provides abstract filesystem access rooted at [vault.rootPath]
/// — path resolution and all I/O happen inside [fileSystem]; this class never
/// imports `dart:io` directly. Every document is a real UTF-8 `.md` file, so
/// notes created here open correctly in Obsidian, and notes created in
/// Obsidian load correctly here.
///
/// ## MVP scope (Sprint 15)
///
/// Implements the five CRUD operations every consumer already depends on —
/// [getByPath], [getAll], [save], [delete], [exists] — reached today through
/// [DailyNoteService] and [DocumentEditorService], neither of which needed
/// any change to gain Obsidian support; they already only know about
/// [DocumentRepository].
///
/// [search] and [getByTag] remain unimplemented, matching the previous stub.
/// Full-text search, tag indexes, backlinks, sync, and conflict resolution
/// are explicitly out of scope for this sprint.
///
/// ## Frontmatter and formatting fidelity
///
/// [Document.content] is always the complete, original file text —
/// frontmatter block included, verbatim. [save] writes that string back
/// unchanged; it never reconstructs YAML from [Document.frontmatter]. That
/// is what makes "never reorder frontmatter" and "preserve unknown fields"
/// actual guarantees rather than best-effort: nothing in this class parses
/// and re-emits the block it was given. [frontmatter] and [tags] on the
/// returned [Document] are a read-side convenience derived by
/// [parseFrontmatter] — they feed the app's own display/filtering, not
/// what gets written to disk.
///
/// ## Unnecessary-write avoidance
///
/// [save] reads the file currently on disk and skips the write entirely
/// when the content is byte-for-byte unchanged. This preserves mtimes for
/// Git and Obsidian plugins that watch the filesystem, and it holds even
/// if a caller invokes [save] directly without going through
/// [DocumentEditorService.saveIfChanged] (which does its own, separate
/// dirty-check against in-memory state — the two checks guard different
/// things and are both worth keeping).
///
/// ## Known limitation: timestamps
///
/// [FileSystemService] exposes no stat/mtime accessor, so this class has
/// no way to read a file's true OS-level creation or modification time.
/// [createdAt]/[updatedAt] are therefore populated at read-time with
/// [DateTime.now()] as an explicit placeholder, and on write, [createdAt]
/// is preserved from the caller-supplied [Document] (never overwritten —
/// consistent with the project-wide "created_at never overwritten"
/// principle) while [updatedAt] only advances when a write actually
/// happens. See Technical Debt in the Sprint 15 summary.
class ObsidianDocumentRepository implements DocumentRepository {
  const ObsidianDocumentRepository({
    required this.vault,
    required this.fileSystem,
  });

  final Vault vault;

  /// Filesystem adapter rooted at [vault.rootPath].
  /// Provided by [fileSystemServiceProvider] in [document_provider.dart].
  final FileSystemService fileSystem;

  // ── Read ──────────────────────────────────────────────────────────

  @override
  Future<Document?> getByPath(String path) async {
    if (!await fileSystem.fileExists(path)) return null;
    final raw = await fileSystem.readFile(path);
    return _fromRaw(path, raw);
  }

  @override
  Future<bool> exists(String path) => fileSystem.fileExists(path);

  /// Recursively walks the vault for every `.md` file and parses each one.
  ///
  /// [FileSystemService.listDirectory] only lists direct children, and a
  /// "standard Obsidian vault layout" nests notes in arbitrary folders, so
  /// this walks manually using only [FileSystemService.listDirectory] and
  /// [FileSystemService.fileExists] — no new filesystem primitive needed.
  /// [fileExists] is what distinguishes a file entry from a subdirectory
  /// entry, since [listDirectory] returns both without marking which.
  ///
  /// Dot-prefixed entries (`.obsidian`, `.trash`, `.git`) are skipped.
  /// Without that, Obsidian's own plugin config and its internal trash
  /// (deleted notes are `.md` files under `.trash/` when Obsidian's
  /// built-in trash is used) would surface here as ordinary documents.
  ///
  /// A single unreadable file (permissions, a race with an external
  /// writer) is skipped rather than failing the whole listing — this
  /// walks a directory tree LifeOS doesn't own or control.
  @override
  Future<List<Document>> getAll() async {
    final paths = await _findMarkdownFiles('');
    final docs = <Document>[];
    for (final path in paths) {
      try {
        final raw = await fileSystem.readFile(path);
        docs.add(_fromRaw(path, raw));
      } catch (_) {
        continue;
      }
    }
    return docs;
  }

  Future<List<String>> _findMarkdownFiles(String dirPath) async {
    final entries = await fileSystem.listDirectory(dirPath);
    final found = <String>[];
    for (final entry in entries) {
      final name = _basename(entry);
      if (name.startsWith('.')) continue;

      if (await fileSystem.fileExists(entry)) {
        if (entry.toLowerCase().endsWith('.md')) found.add(entry);
      } else {
        found.addAll(await _findMarkdownFiles(entry));
      }
    }
    return found;
  }

  // ── Write ─────────────────────────────────────────────────────────

  @override
  Future<Document> save(Document document) async {
    final alreadyExists = await fileSystem.fileExists(document.path);
    var shouldWrite = true;

    if (alreadyExists) {
      final onDisk = await fileSystem.readFile(document.path);
      shouldWrite = onDisk != document.content;
    }

    if (shouldWrite) {
      await fileSystem.writeFile(document.path, document.content);
    }
    // else: content is byte-for-byte identical to what's on disk — skip
    // the write so the file's OS-level mtime is left untouched, for Git
    // and Obsidian-plugin compatibility (Requirement 2).

    // Document.updatedAt (app-level metadata) and the file's mtime
    // (OS-level, guarded above) are independent. save() always stamps
    // updatedAt, matching DocumentRepository's documented contract
    // ("returns the saved document with updated updatedAt") and
    // InternalDocumentRepository's behaviour — copyWith() also preserves
    // createdAt unchanged, so nothing else about the document shifts.
    return document.copyWith();
  }

  @override
  Future<void> delete(String path) async {
    // Idempotent, matching InternalDocumentRepository's SQL DELETE
    // semantics — callers use the shared interface without knowing which
    // adapter is active, so both should behave the same way for a path
    // that's already gone.
    if (await fileSystem.fileExists(path)) {
      await fileSystem.deleteFile(path);
    }
  }

  // ── Deferred (Sprint 15 explicitly excludes these) ──────────────────

  @override
  Future<List<Document>> search(String query) =>
      throw UnimplementedError('ObsidianDocumentRepository not yet implemented');

  @override
  Future<List<Document>> getByTag(String tag) =>
      throw UnimplementedError('ObsidianDocumentRepository not yet implemented');

  // ── Raw text ↔ Document ──────────────────────────────────────────

  Document _fromRaw(String path, String raw) {
    final frontmatter = parseFrontmatter(raw);
    final now = DateTime.now();
    return Document(
      path: path,
      vaultId: vault.id,
      title: _titleFrom(frontmatter, path),
      content: raw,
      frontmatter: frontmatter,
      tags: tagsFromFrontmatter(frontmatter),
      backlinks: const [], // backlinks are out of scope this sprint
      createdAt: now,
      updatedAt: now,
    );
  }

  String _titleFrom(Map<String, dynamic> frontmatter, String path) {
    final fmTitle = frontmatter['title'];
    if (fmTitle is String && fmTitle.trim().isNotEmpty) return fmTitle.trim();

    final fileName = _basename(path);
    return fileName.toLowerCase().endsWith('.md')
        ? fileName.substring(0, fileName.length - 3)
        : fileName;
  }

  String _basename(String path) {
    final slash = path.lastIndexOf('/');
    return slash == -1 ? path : path.substring(slash + 1);
  }
}
