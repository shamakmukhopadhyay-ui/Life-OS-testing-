import 'package:flutter/material.dart';

import '../../../../features/score/logic/score_color_service.dart';

/// A single cell in the monthly calendar grid.
///
/// Accepts [score] as a raw percentage (0.0–100.0) or null for "no data."
/// Colour mapping is delegated entirely to [ScoreColorService] — no
/// colour constants live in this file.
///
/// [isCurrentMonth] controls whether overflow days (from the adjacent
/// month filling the first/last row) are rendered in a muted style.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isCurrentMonth,
    this.score,
    this.isToday = false,
    this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;

  /// Score percentage 0.0–100.0, or null when no data exists for this day.
  final double? score;

  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: isToday
            ? BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? theme.colorScheme.onPrimary
                    : isCurrentMonth
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 2),
            _ScoreDot(
              score: score,
              isPastOrToday: _isPastOrToday(day),
              isCurrentMonth: isCurrentMonth,
              isToday: isToday,
            ),
          ],
        ),
      ),
    );
  }

  static bool _isPastOrToday(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(day.year, day.month, day.day).isAfter(today);
  }
}

/// Coloured dot beneath the day number. Private to this file.
/// All colour decisions delegated to [ScoreColorService].
class _ScoreDot extends StatelessWidget {
  const _ScoreDot({
    required this.score,
    required this.isPastOrToday,
    required this.isCurrentMonth,
    required this.isToday,
  });

  final double? score;
  final bool isPastOrToday;
  final bool isCurrentMonth;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    // Future dates and overflow (adjacent-month) days show no dot.
    if (!isPastOrToday || !isCurrentMonth) return const SizedBox(height: 5);

    // Today's dot is always shown (even with no historical data yet)
    // using the live colour from dailyScoreProvider via the caller.
    final color = ScoreColorService.dotColorForScore(score);

    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
