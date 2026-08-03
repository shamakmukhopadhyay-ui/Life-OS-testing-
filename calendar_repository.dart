import 'dart:math';

import 'day_score_model.dart';

/// Mock data source for calendar day scores.
///
/// Same role as [ObjectivesRepository] and [TasksRepository]: this is the
/// one file that changes when the Score Engine sprint replaces mock data
/// with real computed values. Nothing else in the Calendar feature knows
/// that these numbers are fake.
///
/// Generation strategy — to make the calendar look lived-in:
/// - Future dates:     no data (null score)
/// - Today:            a fixed mid-range score so testing is predictable
/// - Past 60 days:     seeded random scores with a slight positive bias
/// - Before 60 days:  no data (user hadn't started yet)
class CalendarRepository {
  static const int _historyDays = 60;
  final Random _random = Random(42); // fixed seed → deterministic mock data

  /// Returns a map of midnight-normalised [DateTime] → [DayScore] for the
  /// range needed to render [month]. Callers should use [dayKey] to look
  /// up entries so the DateTime comparison is always exact.
  Map<DateTime, DayScore> getScoresForMonth(DateTime month) {
    final today = _midnight(DateTime.now());
    final firstDay = _midnight(DateTime(month.year, month.month, 1));
    final lastDay = _midnight(DateTime(month.year, month.month + 1, 0));

    final map = <DateTime, DayScore>{};

    var cursor = firstDay;
    while (!cursor.isAfter(lastDay)) {
      final dayScore = _scoreForDay(cursor, today);
      if (dayScore != null) {
        map[cursor] = dayScore;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return map;
  }

  DayScore? _scoreForDay(DateTime day, DateTime today) {
    // Future days → no entry
    if (day.isAfter(today)) return null;

    // Days older than history window → no entry
    final cutoff = today.subtract(const Duration(days: _historyDays));
    if (day.isBefore(cutoff)) return null;

    // Today → fixed mid-range score for predictable testing
    if (day == today) {
      return DayScore(
        date: day,
        score: 0.65,
        objectivesCompleted: 1,
        objectivesTotal: 3,
        tasksCompleted: 3,
        tasksTotal: 6,
      );
    }

    // Past days → seeded random
    final score = _clamp(_random.nextDouble() * 0.7 + 0.2); // 0.2 – 0.9
    final tasksTotal = 4 + _random.nextInt(5); // 4–8
    final tasksCompleted = (tasksTotal * score).round();
    final objectivesTotal = 1 + _random.nextInt(3); // 1–3
    final objectivesCompleted = (objectivesTotal * score).round();

    return DayScore(
      date: day,
      score: score,
      objectivesCompleted: objectivesCompleted,
      objectivesTotal: objectivesTotal,
      tasksCompleted: tasksCompleted,
      tasksTotal: tasksTotal,
    );
  }

  double _clamp(double v) => v.clamp(0.0, 1.0);

  /// Normalises a [DateTime] to midnight so map lookups are always exact.
  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Convenience accessor: returns the [DayScore] for a specific day, or
  /// null if no data exists. Callers that already have the full map should
  /// use `map[dayKey(date)]` directly for performance.
  DayScore? getScoreForDay(DateTime date) {
    final today = _midnight(DateTime.now());
    return _scoreForDay(_midnight(date), today);
  }

  /// Normalises [date] to midnight for use as a map key.
  static DateTime dayKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
