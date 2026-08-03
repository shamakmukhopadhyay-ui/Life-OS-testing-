import '../data/daily_score_result.dart';

/// Abstract repository for the `day_scores` table.
///
/// Persists and retrieves computed daily scores for the Calendar
/// Heatmap. Unlike [ObjectivesRepository] and [TasksRepository], this
/// is a snapshot / write-through cache — rows are never deleted, only
/// inserted or replaced.
abstract class DayScoresRepository {
  /// Returns the stored score for every day in [month] that has data.
  ///
  /// The map key is a midnight-normalised [DateTime] (year/month/day
  /// only). The value is the stored score percentage (0.0–100.0).
  /// Days with no recorded data are absent from the map — callers
  /// treat a missing key as "no data" (grey on the heatmap).
  Future<Map<DateTime, double>> getScoresForMonth(DateTime month);

  /// Inserts or replaces the score for [date] in `YYYY-MM-DD` format.
  ///
  /// Called fire-and-forget from the Home screen whenever
  /// [dailyScoreProvider] emits a new value with [DailyScoreResult.totalPoints] > 0.
  Future<void> upsertForDate(DateTime date, DailyScoreResult result);
}
