import 'package:flutter/material.dart';

import 'score_config.dart';

/// Maps a score percentage (or null) to a display colour.
///
/// This is the single source of truth for score-to-colour mapping.
/// Widgets and the calendar legend both import from here — colours are
/// never hardcoded inside a widget.
///
/// Thresholds come from [ScoreConfig] so adjusting a threshold
/// automatically updates every coloured element in the app.
///
/// Colour scheme per spec:
///   null / no data → grey (transparent — no dot shown)
///   0–39           → red
///   40–69          → orange
///   70–89          → amber/yellow
///   90–100         → green
class ScoreColorService {
  ScoreColorService._(); // not instantiable

  /// Full-opacity colour for chips, status labels, and progress rings.
  static Color colorForScore(double? score) {
    if (score == null) return Colors.grey;
    if (score >= ScoreConfig.excellentThreshold) return Colors.green;
    if (score >= ScoreConfig.goodThreshold) return Colors.amber.shade700;
    if (score >= ScoreConfig.fairThreshold) return Colors.orange;
    return Colors.red;
  }

  /// Slightly muted colour for the small calendar grid dot.
  /// Visually distinct from the day number without dominating the cell.
  static Color dotColorForScore(double? score) {
    if (score == null) return Colors.grey.withOpacity(0.35);
    return colorForScore(score).withOpacity(0.85);
  }

  /// Ordered list of (colour, label) pairs for [CalendarLegend].
  /// Kept here so the legend always matches the actual colour logic.
  static const List<(Color, String)> legendItems = [
    (Colors.green, 'Excellent'),
    (Colors.amber, 'Good'),          // shade700 not const-compatible
    (Colors.orange, 'Fair'),
    (Colors.red, 'Needs Work'),
  ];
}
