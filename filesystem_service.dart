import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract filesystem interface used by vault adapters.
///
/// All paths are **relative to the vault root**. The implementing class
/// is responsible for resolving them to absolute paths internally.
///
/// Designed so that [InternalFileSystem] (dart:io) and a future
/// [ObsidianFileSystem] (or [GoogleDriveFileSystem]) implement the same
/// contract. Vault adapters accept a [FileSystemService] rather than
/// importing [dart:io] directly, keeping them testable and swappable.
abstract class FileSystemService {
  /// Reads and returns the full UTF-8 content of the file at [path].
  /// Throws if the file does not exist.
  Future<String> readFile(String path);

  /// Writes [content] to [path], creating parent directories as needed.
  /// Overwrites any existing content.
  Future<void> writeFile(String path, String content);

  /// Creates a new file at [path] with optional [content].
  /// Throws [FileSystemException] if the file already exists.
  Future<void> createFile(String path, {String content = ''});

  /// Permanently deletes the file at [path].
  /// Throws if the file does not exist.
  Future<void> deleteFile(String path);

  /// Returns the relative paths of all entries (files and directories)
  /// directly inside the directory at [dirPath].
  /// Returns an empty list if the directory does not exist.
  Future<List<String>> listDirectory(String dirPath);

  /// Creates the directory at [path], including any intermediate
  /// directories. No-ops if the directory already exists.
  Future<void> createDirectory(String path);

  /// Returns true if a file (not a directory) exists at [path].
  Future<bool> fileExists(String path);
}

/// Provides the active [FileSystemService] to vault adapters.
///
/// Throws [UnimplementedError] until a concrete implementation is
/// registered — the same pattern used by [databaseProvider] and
/// [vaultRepositoryProvider]. Override in [ProviderScope] once the
/// vault root path is resolved (requires `path_provider`, deferred
/// to the sprint that introduces filesystem-backed vault operations):
///
/// ```dart
/// final dir = await getApplicationDocumentsDirectory();
/// ProviderScope(
///   overrides: [
///     fileSystemServiceProvider.overrideWithValue(
///       InternalFileSystem(p.join(dir.path, 'lifeos')),
///     ),
///   ],
///   child: const LifeOSApp(),
/// )
/// ```
final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  throw UnimplementedError(
    'fileSystemServiceProvider has no registered implementation. '
    'Override in ProviderScope with InternalFileSystem(rootPath).',
  );
});
