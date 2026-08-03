import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provides the open [Database] instance to all feature repositories.
///
/// **Must** be overridden in [main] before [runApp]:
/// ```dart
/// final db = await DatabaseService.openDatabase();
/// runApp(ProviderScope(
///   overrides: [databaseProvider.overrideWithValue(db)],
///   child: const LifeOSApp(),
/// ));
/// ```
///
/// Throwing here (rather than opening lazily or returning null) makes a
/// missing initialisation a hard, immediate crash rather than a silent
/// bug that surfaces only when the first query fires.
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError(
    'databaseProvider has not been overridden. '
    'Call DatabaseService.openDatabase() in main() and inject the result '
    'via ProviderScope(overrides: [databaseProvider.overrideWithValue(db)]).',
  );
});

// ── Service ───────────────────────────────────────────────────────────────────

/// Owns the SQLite connection lifecycle and schema definition.
///
/// ## Schema decisions (v1)
///
/// **Single file** — one `lifeos.db` file keeps cross-table queries
/// simple and avoids attach/detach complexity.
///
/// **Enums as TEXT** — stored by their Dart `.name` string ('active',
/// 'high', 'personal', …). Human-readable in the raw file, and
/// `Enum.values.byName()` restores them without a lookup table.
/// Downside: renaming an enum value requires a migration. Mitigated by
/// keeping enum names stable (they map 1-to-1 to what users see).
///
/// **Booleans as INTEGER** — SQLite has no native bool; 0 = false, 1 =
/// true. Checked at the repository layer: `(row['is_completed'] as int) == 1`.
///
/// **Nullable DateTimes as INTEGER** — stored as milliseconds since
/// epoch when present, NULL when absent. Never stored as ISO 8601
/// strings to keep comparisons and ordering in SQL straightforward.
///
/// **linked_tasks_total / linked_tasks_completed are NOT columns** —
/// these are computed at query time via correlated SQL subqueries in
/// [SqliteObjectivesRepository]. Storing them redundantly would require
/// updating the objectives row every time a task changes, creating a
/// second write path. The subquery approach means completing a task
/// immediately reflects in the objective's progress bar on the next
/// objectives load (triggered automatically by [TasksNotifier] via
/// `ref.invalidate`).
///
/// **created_at / updated_at on every row** — milliseconds since epoch.
/// Not displayed in the UI yet, but essential for: default sort order,
/// future sync conflict resolution, and audit trails. Adding these in
/// later would require a migration; adding them now costs one integer
/// per row.
///
/// ## Migration strategy
///
/// Migrations are versioned from v1 using sqflite's built-in [onUpgrade]
/// callback. Even though v1 → v1 never triggers an upgrade, every future
/// column addition (e.g. adding `tags TEXT` to tasks) is a normal
/// `ALTER TABLE` in `_onUpgrade` guarded by `if (oldVersion < N)`.
/// Destructive schema changes are never needed.
class DatabaseService {
  static const String _dbName = 'lifeos.db';
  static const int _schemaVersion = 4;

  /// Opens (or creates) `lifeos.db` in the platform documents directory
  /// and returns a ready [Database]. Called once in [main] before [runApp].
  static Future<Database> openDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, _dbName);

    return sqflite.openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Schema creation ───────────────────────────────────────────────────────

  static Future<void> _onCreate(Database db, int version) async {
    // objectives — long-term / recurring goals.
    // linked_tasks_total and linked_tasks_completed are intentionally
    // absent: they are derived from the tasks table at read time.
    await db.execute('''
      CREATE TABLE objectives (
        id           TEXT    PRIMARY KEY NOT NULL,
        title        TEXT    NOT NULL,
        description  TEXT    NOT NULL DEFAULT '',
        category     TEXT    NOT NULL,
        priority     TEXT    NOT NULL,
        point_value  INTEGER NOT NULL DEFAULT 0,
        status       TEXT    NOT NULL DEFAULT 'active',
        target_date  INTEGER,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL
      )
    ''');

    // tasks — daily action items, optionally linked to an objective.
    // linked_objective_id is a soft FK (no REFERENCES constraint) to
    // avoid cascade-delete complexity before that policy is decided.
    // Referential integrity is enforced at the application layer by the
    // orphan-detection logic in task_form_sheet.dart.
    await db.execute('''
      CREATE TABLE tasks (
        id                   TEXT    PRIMARY KEY NOT NULL,
        title                TEXT    NOT NULL,
        description          TEXT,
        linked_objective_id  TEXT,
        point_value          INTEGER NOT NULL DEFAULT 0,
        due_time             INTEGER,
        priority             TEXT    NOT NULL DEFAULT 'medium',
        is_completed         INTEGER NOT NULL DEFAULT 0,
        created_at           INTEGER NOT NULL,
        updated_at           INTEGER NOT NULL
      )
    ''');

    // day_scores — snapshot table for the Calendar Heatmap (schema v2).
    // One row per calendar date; populated by HomeScreen ref.listen.
    await db.execute("""
      CREATE TABLE day_scores (
        date        TEXT    PRIMARY KEY NOT NULL,
        score       REAL    NOT NULL DEFAULT 0.0,
        earned_pts  INTEGER NOT NULL DEFAULT 0,
        total_pts   INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    """);

    // documents — internal vault store (schema v3, Sprint 11).
    await db.execute("""
      CREATE TABLE documents (
        path        TEXT    PRIMARY KEY NOT NULL,
        vault_id    TEXT    NOT NULL,
        title       TEXT    NOT NULL DEFAULT '',
        content     TEXT    NOT NULL DEFAULT '',
        tags        TEXT    NOT NULL DEFAULT '[]',
        frontmatter TEXT    NOT NULL DEFAULT '{}',
        metadata    TEXT    NOT NULL DEFAULT '{}',
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    """);

    // Schema v4 indexes — improve query performance for current access patterns.
    await db.execute('CREATE INDEX idx_tasks_linked_obj ON tasks(linked_objective_id)');
    await db.execute('CREATE INDEX idx_tasks_completed ON tasks(is_completed)');
    await db.execute('CREATE INDEX idx_objectives_status ON objectives(status)');
    await db.execute('CREATE INDEX idx_documents_vault ON documents(vault_id)');
  }

  // ── Migrations ────────────────────────────────────────────────────────────

  /// Called when the on-disk schema version is older than [_schemaVersion].
  ///
  /// Pattern for future migrations:
  /// ```dart
  /// if (oldVersion < 2) {
      await db.execute("""
        CREATE TABLE IF NOT EXISTS day_scores (
          date        TEXT    PRIMARY KEY NOT NULL,
          score       REAL    NOT NULL DEFAULT 0.0,
          earned_pts  INTEGER NOT NULL DEFAULT 0,
          total_pts   INTEGER NOT NULL DEFAULT 0,
          created_at  INTEGER NOT NULL,
          updated_at  INTEGER NOT NULL
        )
      """);
    }
  /// if (oldVersion < 3) { ... }
  /// ```
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute("""
        CREATE TABLE IF NOT EXISTS day_scores (
          date        TEXT    PRIMARY KEY NOT NULL,
          score       REAL    NOT NULL DEFAULT 0.0,
          earned_pts  INTEGER NOT NULL DEFAULT 0,
          total_pts   INTEGER NOT NULL DEFAULT 0,
          created_at  INTEGER NOT NULL,
          updated_at  INTEGER NOT NULL
        )
      """);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents (
          path        TEXT    PRIMARY KEY NOT NULL,
          vault_id    TEXT    NOT NULL,
          title       TEXT    NOT NULL DEFAULT \'\',
          content     TEXT    NOT NULL DEFAULT \'\',
          tags        TEXT    NOT NULL DEFAULT \'[]\'  ,
          frontmatter TEXT    NOT NULL DEFAULT \'{}\',
          metadata    TEXT    NOT NULL DEFAULT \'{}\',
          created_at  INTEGER NOT NULL,
          updated_at  INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_linked_obj ON tasks(linked_objective_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(is_completed)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_objectives_status ON objectives(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_vault ON documents(vault_id)');
    }
  }
}
