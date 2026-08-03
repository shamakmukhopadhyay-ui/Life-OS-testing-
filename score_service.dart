import '../../objectives/data/objective_model.dart';
import '../../tasks/data/task_model.dart';
import '../data/daily_score_result.dart';

/// Calculates a [DailyScoreResult] from the current objectives and tasks.
///
/// ## Algorithm
///
/// **Objectives** (long-term goals):
/// - `totalObjectivePoints`  = Σ pointValue  for all non-archived objectives
/// - `earnedObjectivePoints` = Σ pointValue  for completed objectives only
///
/// Archived objectives are excluded because they represent goals the user
/// has consciously set aside — they should neither help nor hurt the score.
/// Active objectives that are not yet completed contribute to the total
/// (raising the bar) but zero to earned (keeping the user honest).
///
/// **Tasks** (daily action items):
/// - `totalTaskPoints`  = Σ pointValue  for all tasks
/// - `earnedTaskPoints` = Σ pointValue  for completed tasks
///
/// **Overall daily score**:
/// ```
/// scorePercent = (earnedObjectivePoints + earnedTaskPoints)
///             / (totalObjectivePoints  + totalTaskPoints)
///             * 100
/// ```
/// Returns 0.0 when the denominator is zero (no data yet).
///
/// ## Why not hardcode thresholds here?
///
/// The [DailyStatus] thresholds (90/70/40) live on [DailyScoreResult]
/// itself. This service only produces numbers — it does not decide what
/// label to display. That boundary keeps the algorithm testable without
/// any dependency on how the UI interprets results.
class ScoreService {
  // Prevent instantiation — this is a pure function namespace.
  ScoreService._();

  /// Computes today's [DailyScoreResult] from [objectives] and [tasks].
  ///
  /// Both lists can be empty; the service handles the zero-total edge
  /// case by returning [DailyScoreResult.empty].
  static DailyScoreResult calculate({
    required List<Objective> objectives,
    required List<Task> tasks,
  }) {
    // ── Objectives ──────────────────────────────────────────────────
    // Exclude archived so they don't dilute or inflate the score.
    final scoredObjectives = objectives
        .where((o) => o.status != ObjectiveStatus.archived)
        .toList();

    final totalObjectivePoints = scoredObjectives.fold<int>(
      0,
      (sum, o) => sum + o.pointValue,
    );

    final earnedObjectivePoints = scoredObjectives
        .where((o) => o.status == ObjectiveStatus.completed)
        .fold<int>(0, (sum, o) => sum + o.pointValue);

    // ── Tasks ────────────────────────────────────────────────────────
    final totalTaskPoints = tasks.fold<int>(
      0,
      (sum, t) => sum + t.pointValue,
    );

    final earnedTaskPoints = tasks
        .where((t) => t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.pointValue);

    // ── Early-exit if nothing to score yet ──────────────────────────
    if (totalObjectivePoints + totalTaskPoints == 0) {
      return DailyScoreResult.empty;
    }

    return DailyScoreResult(
      totalObjectivePoints: totalObjectivePoints,
      earnedObjectivePoints: earnedObjectivePoints,
      totalTaskPoints: totalTaskPoints,
      earnedTaskPoints: earnedTaskPoints,
    );
  }
}
