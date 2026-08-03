import 'package:sqflite/sqflite.dart';

import 'objective_model.dart';
import 'objectives_repository.dart';

/// SQLite-backed implementation of [ObjectivesRepository].
///
/// This is the active implementation wired into the running app via
/// [objectivesRepositoryProvider] in [objectives_provider.dart].
///
/// ## Linked-task progress
///
/// [Objective.linkedTasksTotal] and [Objective.linkedTasksCompleted] are
/// not stored in the objectives table — they are computed at read time
/// via two correlated subqueries in [getAll]. This approach:
///
/// - Eliminates redundant data that can fall out of sync.
/// - Means marking a task complete immediately reflects in the linked
///   objective's progress bar on the next objectives load.
/// - Loads in a single SELECT (no extra round-trips).
///
/// [TasksNotifier] calls `ref.invalidate(objectivesProvider)` after
/// every task mutation, triggering a [getAll] reload automatically.
///
/// ## Insert vs Update maps
///
/// `created_at` is set once on insert and never written again on update.
/// Two separate maps (_toInsertMap / _toUpdateMap) make this explicit
/// and prevent accidental overwriting of the creation timestamp.
class SqliteObjectivesRepository implements ObjectivesRepository {
  const SqliteObjectivesRepository(this._db);

  final Database _db;
  static const _table = 'objectives';

  // ── Read ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Objective>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT
        o.id,
        o.title,
        o.description,
        o.category,
        o.priority,
        o.point_value,
        o.status,
        o.target_date,
        o.created_at,
        o.updated_at,
        (
          SELECT COUNT(*)
            FROM tasks t
           WHERE t.linked_objective_id = o.id
        ) AS linked_tasks_total,
        (
          SELECT COUNT(*)
            FROM tasks t
           WHERE t.linked_objective_id = o.id
             AND t.is_completed = 1
        ) AS linked_tasks_completed
      FROM objectives o
      ORDER BY o.created_at DESC
    ''');
    return rows.map(_fromRow).toList();
  }

  // ── Write ────────────────────────────────────────────────────────────────

  @override
  Future<void> insert(Objective objective) async {
    await _db.insert(
      _table,
      _toInsertMap(objective),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Objective objective) async {
    await _db.update(
      _table,
      _toUpdateMap(objective),
      where: 'id = ?',
      whereArgs: [objective.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Row ↔ Model ──────────────────────────────────────────────────────────

  Objective _fromRow(Map<String, dynamic> row) {
    return Objective(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      category:
          ObjectiveCategory.values.byName(row['category'] as String),
      priority:
          ObjectivePriority.values.byName(row['priority'] as String),
      pointValue: row['point_value'] as int,
      status: ObjectiveStatus.values.byName(row['status'] as String),
      targetDate: row['target_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['target_date'] as int)
          : null,
      // Subquery columns: present in every getAll() row.
      linkedTasksTotal: (row['linked_tasks_total'] as int?) ?? 0,
      linkedTasksCompleted: (row['linked_tasks_completed'] as int?) ?? 0,
    );
  }

  /// Full row map for INSERT — includes id and created_at.
  Map<String, dynamic> _toInsertMap(Objective o) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': o.id,
      'title': o.title,
      'description': o.description,
      'category': o.category.name,
      'priority': o.priority.name,
      'point_value': o.pointValue,
      'status': o.status.name,
      'target_date': o.targetDate?.millisecondsSinceEpoch,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Partial row map for UPDATE — excludes id (in WHERE) and created_at
  /// (must never be overwritten once set).
  Map<String, dynamic> _toUpdateMap(Objective o) {
    return {
      'title': o.title,
      'description': o.description,
      'category': o.category.name,
      'priority': o.priority.name,
      'point_value': o.pointValue,
      'status': o.status.name,
      'target_date': o.targetDate?.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
