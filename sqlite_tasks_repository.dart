import 'package:sqflite/sqflite.dart';

import 'task_model.dart';
import 'tasks_repository.dart';

/// SQLite-backed implementation of [TasksRepository].
///
/// The active implementation wired in via [tasksRepositoryProvider].
///
/// ## Schema mapping
///
/// | Dart field          | Column              | SQLite type | Notes                                    |
/// |---------------------|---------------------|-------------|------------------------------------------|
/// | id                  | id                  | TEXT PK     |                                          |
/// | title               | title               | TEXT        |                                          |
/// | description         | description         | TEXT        | nullable                                 |
/// | linkedObjectiveId   | linked_objective_id | TEXT        | nullable soft FK                         |
/// | pointValue          | point_value         | INTEGER     |                                          |
/// | dueTime             | due_time            | INTEGER     | nullable ms-since-epoch; see note below  |
/// | priority            | priority            | TEXT        | enum .name ('low','medium',…)            |
/// | isCompleted         | is_completed        | INTEGER     | 0 = false, 1 = true                      |
/// | —                   | created_at          | INTEGER     | set on insert only                       |
/// | —                   | updated_at          | INTEGER     | set on every write                       |
///
/// ### due_time schema note
///
/// `due_time` is stored as an absolute ms-since-epoch timestamp (the full
/// DateTime of when the user saved the task, not just the time component).
/// On read, [_fromRow] re-anchors the stored hour/minute to the current
/// date via [_reanchorToToday]. This means "due at 18:00" always means
/// "today at 18:00" regardless of when the task was created, which matches
/// the field's semantic purpose: a time-of-day, not an absolute moment.
///
/// **Before the Score Engine sprint:** migrate this column to store
/// minute-of-day as a plain INTEGER (0–1439) so SQL range queries
/// (e.g. `WHERE due_time < 720`) work correctly without date arithmetic.
/// That requires a schema v2 migration in [DatabaseService._onUpgrade].
class SqliteTasksRepository implements TasksRepository {
  const SqliteTasksRepository(this._db);

  final Database _db;
  static const _table = 'tasks';

  // ── Read ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Task>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  // ── Write ────────────────────────────────────────────────────────────────

  @override
  Future<void> insert(Task task) async {
    await _db.insert(
      _table,
      _toInsertMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Task task) async {
    await _db.update(
      _table,
      _toUpdateMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Row ↔ Model ──────────────────────────────────────────────────────────

  Task _fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      linkedObjectiveId: row['linked_objective_id'] as String?,
      pointValue: row['point_value'] as int,
      dueTime: row['due_time'] != null
          ? _reanchorToToday(
              DateTime.fromMillisecondsSinceEpoch(row['due_time'] as int))
          : null,
      priority: TaskPriority.values.byName(row['priority'] as String),
      isCompleted: (row['is_completed'] as int) == 1,
    );
  }

  /// Re-anchors a stored due-time timestamp to today's date.
  ///
  /// Stored timestamps carry the full date from the day the task was
  /// created. This helper extracts only the hour and minute components
  /// and returns a new [DateTime] set to today — so "due at 18:00" always
  /// reads back as "today at 18:00" regardless of the creation date.
  ///
  /// This is intentionally called on every [_fromRow] read. When the
  /// Score Engine sprint migrates [due_time] to a minute-of-day integer,
  /// this method is removed and replaced with a simple int read.
  DateTime _reanchorToToday(DateTime stored) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, stored.hour, stored.minute);
  }

  Map<String, dynamic> _toInsertMap(Task t) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'linked_objective_id': t.linkedObjectiveId,
      'point_value': t.pointValue,
      'due_time': t.dueTime?.millisecondsSinceEpoch,
      'priority': t.priority.name,
      'is_completed': t.isCompleted ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Excludes id (used in WHERE) and created_at (must never change).
  Map<String, dynamic> _toUpdateMap(Task t) {
    return {
      'title': t.title,
      'description': t.description,
      'linked_objective_id': t.linkedObjectiveId,
      'point_value': t.pointValue,
      'due_time': t.dueTime?.millisecondsSinceEpoch,
      'priority': t.priority.name,
      'is_completed': t.isCompleted ? 1 : 0,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
