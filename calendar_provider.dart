import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_repository.dart';
import '../data/day_score_model.dart';

/// Repository provider — overridable for tests or when the Score Engine
/// replaces mock data, same pattern as every other feature.
final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => CalendarRepository());

/// Holds the month currently displayed in the calendar grid.
/// Initialises to the current month. Navigation arrows call
/// [previousMonth] / [nextMonth].
class CalendarMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  /// Jumps directly to [month]'s year/month (used by "Today" shortcut).
  void goToMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }
}

final calendarMonthProvider =
    NotifierProvider<CalendarMonthNotifier, DateTime>(
  CalendarMonthNotifier.new,
);

/// Derived provider: the score map for the currently displayed month.
/// Recomputes automatically when [calendarMonthProvider] changes.
final monthScoresProvider = Provider<Map<DateTime, DayScore>>((ref) {
  final month = ref.watch(calendarMonthProvider);
  final repo = ref.read(calendarRepositoryProvider);
  return repo.getScoresForMonth(month);
});

/// Convenience provider: score for a specific day. Reads from the
/// current month's score map if the day falls in that month; otherwise
/// asks the repository directly. Used by [DaySummaryScreen].
final dayScoreProvider =
    Provider.family<DayScore?, DateTime>((ref, date) {
  final key = CalendarRepository.dayKey(date);
  final monthScores = ref.watch(monthScoresProvider);

  // Fast path: the day is already in the loaded month map.
  if (monthScores.containsKey(key)) return monthScores[key];

  // Slow path: day is outside the viewed month (e.g. navigated directly
  // from a deep link). Ask the repository directly.
  return ref.read(calendarRepositoryProvider).getScoreForDay(date);
});
