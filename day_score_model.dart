/// Represents a single calendar day's completion snapshot.
///
/// Pure Dart — no Flutter import. This model is intentionally thin: it
/// holds only what the calendar grid and day-summary screen need to
/// display. The Score Engine sprint will be responsible for computing
/// real values; right now the mock repository sets plausible-looking
/// numbers directly.
///
/// [score] drives the colour indicator on the calendar grid:
///   >= 0.8  → green  (Excellent)
///   >= 0.6  → yellow (Good)
///   >= 0.4  → orange (Average)
///   >  0.0  → red    (Poor)
///   == null → grey   (No data — future dates, or dates with no activity)
///
/// The [objectivesCompleted]/[objectivesTotal] and
/// [tasksCompleted]/[tasksTotal] fields are stored as plain counts rather
/// than lists of objects, so this model stays independent of the
/// Objectives and Tasks features. The DaySummaryScreen resolves the
/// actual items separately from the providers that own them.

enum DayRating { excellent, good, average, poor, noData }

class DayScore {
  const DayScore({
    required this.date,
    this.score,
    this.objectivesCompleted = 0,
    this.objectivesTotal = 0,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
  });

  /// Midnight on the day this record represents.
  final DateTime date;

  /// Normalised completion score 0.0–1.0, or null if no data exists for
  /// this day (e.g. future dates, or days before the user started using
  /// the app).
  final double? score;

  final int objectivesCompleted;
  final int objectivesTotal;
  final int tasksCompleted;
  final int tasksTotal;

  /// Derives a [DayRating] from [score] for use in colour mapping.
  DayRating get rating {
    final s = score;
    if (s == null) return DayRating.noData;
    if (s >= 0.8) return DayRating.excellent;
    if (s >= 0.6) return DayRating.good;
    if (s >= 0.4) return DayRating.average;
    return DayRating.poor;
  }

  /// True when the day has at least some recorded activity.
  bool get hasData => score != null;
}
