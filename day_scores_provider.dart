import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../data/day_scores_repository.dart';
import '../data/sqlite_day_scores_repository.dart';
import 'score_provider.dart';

/// Wires the active [DayScoresRepository] implementation.
final dayScoresRepositoryProvider = Provider<DayScoresRepository>((ref) {
  return SqliteDayScoresRepository(ref.watch(databaseProvider));
});

/// Provides the score map for a calendar month as an [AsyncValue].
///
/// **Parameter:** [month] — any [DateTime] in the target month; only
/// year and month are used.
///
/// **Returns:** `Map<DateTime, double>` where each key is a
/// midnight-normalised date and the value is that day's score (0.0–100.0).
/// Days absent from the map have no data and render grey on the heatmap.
///
/// **Live override for today:** this provider watches [dailyScoreProvider]
/// so it automatically re-runs whenever a task or objective changes. The
/// current day's entry is always overridden with the live computed score,
/// meaning the calendar dot for today updates in real time without waiting
/// for the score to be persisted to SQLite first.
///
/// **For other days:** scores are read from the `day_scores` SQLite table,
/// which is populated by the [ref.listen] listener in [HomeScreen] (fires
/// on every [dailyScoreProvider] change while the dashboard is visible).
final monthDayScoresProvider =
    FutureProvider.family<Map<DateTime, double>, DateTime>(
        (ref, month) async {
  // Watching dailyScoreProvider causes this future to re-run whenever
  // the live score changes, keeping today's dot current.
  final liveScore = ref.watch(dailyScoreProvider);

  final repo = ref.read(dayScoresRepositoryProvider);
  // Stored scores for the month — mutable copy so we can patch today.
  final stored = Map<DateTime, double>.from(
    await repo.getScoresForMonth(month),
  );

  // Override today's entry with the live score so the dot is always
  // accurate regardless of whether the score has been persisted yet.
  final now = DateTime.now();
  final todayKey = DateTime(now.year, now.month, now.day);
  if (liveScore.totalPoints > 0) {
    stored[todayKey] = liveScore.scorePercent;
  }

  return stored;
});
