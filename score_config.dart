/// Central configuration for the Daily Score Engine.
///
/// All threshold values and weighting constants live here so future
/// balancing requires changing one file, not hunting through service
/// logic or widget code.
///
/// Usage:
///   if (score >= ScoreConfig.excellentThreshold) → Excellent
///   if (score >= ScoreConfig.goodThreshold)       → Good
///   if (score >= ScoreConfig.fairThreshold)       → Fair
///   else                                          → Needs Improvement
///
/// The same thresholds drive:
///   - [DailyScoreResult.status] (score status label)
///   - [ScoreColorService.colorForScore] (calendar dot colours)
///   - [CalendarLegend] (legend labels)
class ScoreConfig {
  ScoreConfig._(); // not instantiable

  // ── Status thresholds (scorePercent, 0.0 – 100.0) ────────────────
  static const double excellentThreshold = 90.0;
  static const double goodThreshold = 70.0;
  static const double fairThreshold = 40.0;

  // ── Future weighting rules (not yet active) ───────────────────────
  // When the Score Engine supports weighted categories, add constants
  // here (e.g. objectiveWeight, taskWeight) and reference them from
  // ScoreService.calculate(). No logic changes are needed in widgets.
}
