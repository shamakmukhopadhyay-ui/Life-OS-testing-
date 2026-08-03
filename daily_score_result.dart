import 'score_config.dart';
///
/// Pure Dart — no Flutter or Riverpod imports. All derived fields are
/// computed properties on the model rather than computed separately
/// in the UI, so every consumer gets the same numbers from a single
/// source of truth.
library;

/// Maps [DailyScoreResult.scorePercent] to a user-facing status label.
///
/// Thresholds per spec:
///   90–100  → Excellent
///   70–89   → Good
///   40–69   → Fair
///   < 40    → Needs Improvement
enum DailyStatus { excellent, good, fair, needsImprovement }

/// Immutable snapshot of a single day's score calculation.
///
/// Created by [ScoreService.calculate] and never mutated. If the
/// underlying objectives or tasks change, a new result is produced.
class DailyScoreResult {
  const DailyScoreResult({
    required this.totalObjectivePoints,
    required this.earnedObjectivePoints,
    required this.totalTaskPoints,
    required this.earnedTaskPoints,
  });

  // ── Raw components ────────────────────────────────────────────────

  /// Sum of [pointValue] for all non-archived objectives.
  final int totalObjectivePoints;

  /// Sum of [pointValue] for objectives whose status is `completed`.
  final int earnedObjectivePoints;

  /// Sum of [pointValue] for all tasks.
  final int totalTaskPoints;

  /// Sum of [pointValue] for tasks where `isCompleted == true`.
  final int earnedTaskPoints;

  // ── Derived totals ────────────────────────────────────────────────

  int get totalPoints => totalObjectivePoints + totalTaskPoints;
  int get earnedPoints => earnedObjectivePoints + earnedTaskPoints;

  /// Points still needed to reach 100 % of today's total.
  int get remainingPoints => totalPoints - earnedPoints;

  // ── Score and status ──────────────────────────────────────────────

  /// Overall daily score as a percentage, 0.0–100.0.
  /// Returns 0.0 when [totalPoints] == 0 (no data yet).
  double get scorePercent => totalPoints == 0
      ? 0.0
      : (earnedPoints / totalPoints * 100).clamp(0.0, 100.0);

  /// Normalised 0.0–1.0 value for use with [CircularProgressIndicator].
  double get scoreValue => scorePercent / 100;

  DailyStatus get status {
    if (scorePercent >= ScoreConfig.excellentThreshold) return DailyStatus.excellent;
    if (scorePercent >= ScoreConfig.goodThreshold) return DailyStatus.good;
    if (scorePercent >= ScoreConfig.fairThreshold) return DailyStatus.fair;
    return DailyStatus.needsImprovement;
  }

  String get statusLabel => switch (status) {
        DailyStatus.excellent => 'Excellent',
        DailyStatus.good => 'Good',
        DailyStatus.fair => 'Fair',
        DailyStatus.needsImprovement => 'Needs Improvement',
      };

  /// A zero-point result used before any data has loaded.
  static const empty = DailyScoreResult(
    totalObjectivePoints: 0,
    earnedObjectivePoints: 0,
    totalTaskPoints: 0,
    earnedTaskPoints: 0,
  );
}
