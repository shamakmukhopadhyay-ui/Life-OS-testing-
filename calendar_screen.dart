import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../score/logic/day_scores_provider.dart';
import '../logic/calendar_provider.dart';
import 'widgets/calendar_day_cell.dart';
import 'widgets/calendar_legend.dart';

/// Monthly calendar screen.
///
/// Each day cell shows a coloured dot derived from the stored daily
/// score in the `day_scores` SQLite table, via [monthDayScoresProvider].
/// Today's dot is always live (overridden by [dailyScoreProvider]).
/// Colour mapping is handled entirely by [ScoreColorService] — no
/// colours are hardcoded in this file or in [CalendarDayCell].
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const List<String> _weekdayHeaders = [
    'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su',
  ];

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final monthNotifier = ref.read(calendarMonthProvider.notifier);
    final scoresAsync = ref.watch(monthDayScoresProvider(month));
    final theme = Theme.of(context);
    final today = DateTime.now();
    final days = _buildDayGrid(month);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: monthNotifier.previousMonth,
              tooltip: 'Previous month',
            ),
            Text(
              '${_monthNames[month.month - 1]} ${month.year}',
              style: theme.textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: monthNotifier.nextMonth,
              tooltip: 'Next month',
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => monthNotifier.goToMonth(today),
            child: const Text('Today'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                children: [
                  // Weekday header row — always visible, not async.
                  Row(
                    children: _weekdayHeaders
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  // Grid — gated on async score load.
                  scoresAsync.when(
                    loading: () => const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Expanded(
                      child: Center(
                        child: Text(
                          'Could not load scores',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    data: (scores) => Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final (day, isCurrentMonth) = days[index];
                          final dayKey = DateTime(
                              day.year, day.month, day.day);
                          final isToday = day.year == today.year &&
                              day.month == today.month &&
                              day.day == today.day;

                          return CalendarDayCell(
                            day: day,
                            isCurrentMonth: isCurrentMonth,
                            score: scores[dayKey],
                            isToday: isToday,
                            onTap: isCurrentMonth
                                ? () => _openDaySummary(context, day)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const CalendarLegend(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDaySummary(BuildContext context, DateTime day) {
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    context.push('/calendar/$dateStr');
  }

  List<(DateTime, bool)> _buildDayGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final leadingEmpties = firstDay.weekday - 1;
    final trailingEmpties = (7 - lastDay.weekday) % 7;
    final result = <(DateTime, bool)>[];

    for (var i = leadingEmpties; i > 0; i--) {
      result.add((firstDay.subtract(Duration(days: i)), false));
    }
    for (var d = 1; d <= lastDay.day; d++) {
      result.add((DateTime(month.year, month.month, d), true));
    }
    for (var i = 1; i <= trailingEmpties; i++) {
      result.add((lastDay.add(Duration(days: i)), false));
    }
    return result;
  }
}
