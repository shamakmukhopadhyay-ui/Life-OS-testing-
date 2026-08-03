import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists Quick Clipboard's single block of text — Sprint 22 V2-02
/// Task 4.
///
/// Abstract, matching every other repository in this project
/// (`DocumentRepository`, `TasksRepository`) — Presentation/Logic code
/// depends on this interface, never on `FileQuickClipboardRepository`
/// directly.
abstract class QuickClipboardRepository {
  /// The currently-saved text, or an empty string if nothing has been
  /// saved yet.
  Future<String> read();

  /// Overwrites the saved text with [content].
  Future<void> write(String content);
}

/// Stores the clipboard's text as a single plain-text file in the
/// platform's app documents directory.
///
/// Deliberately not SQLite: this sprint's own regression check forbids
/// SQLite changes, and adding a table for a single block of text would
/// be disproportionate anyway. Deliberately not reusing
/// `FileSystemService`/`InternalFileSystem` (the vault-adapter
/// abstraction, Sprint 15) either — that abstraction is scoped to
/// vault-relative paths for `Document`s; this is a single, fixed,
/// app-level file with no vault concept, so a small, direct `dart:io`
/// implementation is the more honest fit than bending a vault-shaped
/// interface around a non-vault file.
class FileQuickClipboardRepository implements QuickClipboardRepository {
  const FileQuickClipboardRepository();

  Future<File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/quick_clipboard.txt');
  }

  @override
  Future<String> read() async {
    final file = await _resolveFile();
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  @override
  Future<void> write(String content) async {
    final file = await _resolveFile();
    await file.writeAsString(content);
  }
}
