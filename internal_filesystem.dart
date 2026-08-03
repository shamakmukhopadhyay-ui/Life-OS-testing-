import 'dart:io';

import 'package:path/path.dart' as p;

import 'filesystem_service.dart';

/// [dart:io]-backed implementation of [FileSystemService].
///
/// [rootPath] is the absolute base directory for this vault (e.g.
/// `{appDocDir}/lifeos` for the internal vault, or the user-configured
/// Obsidian vault directory). All relative paths passed to methods are
/// joined to [rootPath] before any I/O operation.
///
/// Not web-compatible — [dart:io] is unavailable on Flutter Web.
/// LifeOS is a mobile-first app; web support is not in scope.
class InternalFileSystem implements FileSystemService {
  const InternalFileSystem(this.rootPath);

  /// Absolute path to the vault root on the local filesystem.
  final String rootPath;

  // ── Helpers ───────────────────────────────────────────────────────

  /// Resolves [relativePath] to an absolute path under [rootPath].
  String _abs(String relativePath) => p.join(rootPath, relativePath);

  // ── Read ──────────────────────────────────────────────────────────

  @override
  Future<String> readFile(String path) => File(_abs(path)).readAsString();

  @override
  Future<bool> fileExists(String path) => File(_abs(path)).exists();

  @override
  Future<List<String>> listDirectory(String dirPath) async {
    final dir = Directory(_abs(dirPath));
    if (!await dir.exists()) return const [];
    final entries = await dir.list().toList();
    // Return paths relative to rootPath for caller consistency.
    return entries
        .map((e) => p.relative(e.path, from: rootPath))
        .toList();
  }

  // ── Write ─────────────────────────────────────────────────────────

  @override
  Future<void> writeFile(String path, String content) async {
    final file = File(_abs(path));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<void> createFile(String path, {String content = ''}) async {
    final file = File(_abs(path));
    if (await file.exists()) {
      throw FileSystemException(
          'File already exists — use writeFile to overwrite.', _abs(path));
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<void> createDirectory(String path) =>
      Directory(_abs(path)).create(recursive: true);

  @override
  Future<void> deleteFile(String path) => File(_abs(path)).delete();
}
