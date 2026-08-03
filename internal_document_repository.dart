import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'document_model.dart';
import 'document_repository.dart';
import 'vault_model.dart';

/// SQLite-backed [DocumentRepository] for the internal vault.
///
/// All documents live in the `documents` table (schema v3). Content is
/// stored as TEXT — no filesystem access needed for MVP. Tags, frontmatter,
/// and metadata are stored as JSON strings and decoded on read.
///
/// Every query is scoped to [vault.id] so multiple vaults can coexist
/// in the same table without collision.
class InternalDocumentRepository implements DocumentRepository {
  const InternalDocumentRepository({
    required this.vault,
    required this.db,
  });

  final Vault vault;
  final Database db;
  static const _table = 'documents';

  // ── Read ─────────────────────────────────────────────────────────

  @override
  Future<Document?> getByPath(String path) async {
    final rows = await db.query(
      _table,
      where: 'path = ? AND vault_id = ?',
      whereArgs: [path, vault.id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<Document>> getAll() async {
    final rows = await db.query(
      _table,
      where: 'vault_id = ?',
      whereArgs: [vault.id],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<bool> exists(String path) async {
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $_table WHERE path = ? AND vault_id = ?',
      [path, vault.id],
    ));
    return (count ?? 0) > 0;
  }

  /// Basic LIKE search across title and content.
  /// Full-text search (FTS5) is deferred — tagged as tech debt.
  @override
  Future<List<Document>> search(String query) async {
    final rows = await db.query(
      _table,
      where: 'vault_id = ? AND (title LIKE ? OR content LIKE ?)',
      whereArgs: [vault.id, '%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Substring match on the JSON tags array.
  /// Proper indexing deferred — tagged as tech debt.
  @override
  Future<List<Document>> getByTag(String tag) async {
    final rows = await db.query(
      _table,
      where: 'vault_id = ? AND tags LIKE ?',
      whereArgs: [vault.id, '%"$tag"%'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  // ── Write ─────────────────────────────────────────────────────────

  @override
  Future<Document> save(Document document) async {
    if (await exists(document.path)) {
      await db.update(
        _table,
        _toUpdateMap(document),
        where: 'path = ? AND vault_id = ?',
        whereArgs: [document.path, vault.id],
      );
    } else {
      await db.insert(
        _table,
        _toInsertMap(document),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return (await getByPath(document.path))!;
  }

  @override
  Future<void> delete(String path) async {
    await db.delete(
      _table,
      where: 'path = ? AND vault_id = ?',
      whereArgs: [path, vault.id],
    );
  }

  // ── Row ↔ Model ───────────────────────────────────────────────────

  Document _fromRow(Map<String, dynamic> row) {
    return Document(
      path: row['path'] as String,
      vaultId: row['vault_id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      tags: List<String>.from(
          jsonDecode(row['tags'] as String) as List),
      frontmatter: Map<String, dynamic>.from(
          jsonDecode(row['frontmatter'] as String) as Map),
      metadata: Map<String, dynamic>.from(
          jsonDecode(row['metadata'] as String) as Map),
      backlinks: const [], // backlinks not yet persisted
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  Map<String, dynamic> _toInsertMap(Document d) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'path': d.path,
      'vault_id': d.vaultId,
      'title': d.title,
      'content': d.content,
      'tags': jsonEncode(d.tags),
      'frontmatter': jsonEncode(d.frontmatter),
      'metadata': jsonEncode(d.metadata),
      'created_at': now,
      'updated_at': now,
    };
  }

  // created_at intentionally excluded — must never change after insert.
  Map<String, dynamic> _toUpdateMap(Document d) {
    return {
      'title': d.title,
      'content': d.content,
      'tags': jsonEncode(d.tags),
      'frontmatter': jsonEncode(d.frontmatter),
      'metadata': jsonEncode(d.metadata),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
