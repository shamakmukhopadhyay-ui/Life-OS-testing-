import 'package:sqflite/sqflite.dart';

import 'daily_score_result.dart';
import 'day_scores_repository.dart';

/// SQLite-backed implementation of [DayScoresRepository].
///
/// Date format throughout: ISO 8601 `YYYY-MM-DD` stored as TEXT.
/// This sorts correctly without conversion and is unambiguous
/// across timezones (no time component is ever stored).
class SqliteDayScoresRepository implements DayScoresRepository {
  const SqliteDayScoresRepository(this._db);

  final Database _db;
  static const _table = 'day_scores';

  // ── Read ─────────────────────────────────────────────────────────

  @override
  Future<Map<DateTime, double>> getScoresForMonth(DateTime month) async {
    // Build the first and last day of the month as date strings.
    // Using '31' as the upper bound is safe — SQLite TEXT comparison
    // stops at the actual last day because dates like '2025-07-32'
    // never exist in the table.
    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final start = '$prefix-01';
    final end = '$prefix-31';

    final rows = await _db.query(
      _table,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
    );

    final result = <DateTime, double>{};
    for (final row in rows) {
      final totalPts = row['total_pts'] as int;
      // Only include rows with meaningful data; a row with total_pts=0
      // means the score was 0.0 due to no tasks/objectives, which is
      // indistinguishable from "no data" — treat both as absent.
      if (totalPts == 0) continue;

      final key = _parseDateKey(row['date'] as String);
      result[key] = row['score'] as double;
    }
    return result;
  }

  // ── Write ─────────────────────────────────────────────────────────

  @override
  Future<void> upsertForDate(DateTime date, DailyScoreResult result) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert(
      _table,
      {
        'date': _formatDateKey(date),
        'score': result.scorePercent,
        'earned_pts': result.earnedPoints,
        'total_pts': result.totalPoints,
        'created_at': now,
        'updated_at': now,
      },
      // Replace the entire row — today's score is always the latest
      // computed value, not an immutable creation event.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  /// Converts a `DateTime` to a `YYYY-MM-DD` string used as the PK.
  static String _formatDateKey(DateTime dt) =>
      '${dt.year}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// Parses a `YYYY-MM-DD` string back to a midnight [DateTime].
  static DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
