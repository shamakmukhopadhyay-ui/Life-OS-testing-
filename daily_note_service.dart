import '../data/document_model.dart';
import '../data/document_repository.dart';
import '../data/vault_model.dart';

/// Owns the daily note naming convention and retrieval logic.
///
/// No screen or provider computes a daily note path directly — they
/// call [DailyNoteService.dailyNotePath] so the convention is defined
/// in exactly one place.
///
/// ## Path convention
///
/// ```
/// daily/YYYY-MM-DD.md
/// ```
///
/// This relative path is used by both [InternalDocumentRepository]
/// (relative to `{appDocDir}/lifeos/`) and [ObsidianDocumentRepository]
/// (relative to the vault root). If a user's Obsidian vault uses a
/// different structure, [ObsidianDocumentRepository] applies its own
/// path-mapping before delegating to this convention.
class DailyNoteService {
  DailyNoteService._();

  /// Returns the canonical path for a daily note, e.g.
  /// `daily/2025-07-11.md`.
  static String dailyNotePath(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'daily/$y-$m-$d.md';
  }

  /// Returns the existing daily note for [date], or null if none.
  static Future<Document?> get(
    DocumentRepository repo,
    DateTime date,
  ) =>
      repo.getByPath(dailyNotePath(date));

  /// Returns the existing daily note, or creates and saves a blank one.
  static Future<Document> getOrCreate(
    DocumentRepository repo,
    DateTime date,
    Vault vault, // the active vault this note belongs to
  ) async {
    final path = dailyNotePath(date);
    final existing = await repo.getByPath(path);
    if (existing != null) return existing;

    final now = DateTime.now();
    final title = _formatTitle(date);
    final newDoc = Document(
      path: path,
      title: title,
      content: '---\ntitle: $title\ndate: ${path.substring(6, 16)}\ntags: [daily]\n---\n\n',
      vaultId: vault.id,
      frontmatter: {
        'title': title,
        'date': path.substring(6, 16),
        'tags': ['daily'],
      },
      tags: const ['daily'],
      createdAt: now,
      updatedAt: now,
    );
    return repo.save(newDoc);
  }

  static String _formatTitle(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return 'Daily Note — ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
