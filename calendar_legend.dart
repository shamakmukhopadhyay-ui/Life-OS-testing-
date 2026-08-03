import 'package:flutter/material.dart';

import '../../../../features/score/logic/score_color_service.dart';

/// Colour legend shown below the calendar grid.
///
/// Labels and colours come from [ScoreColorService.legendItems] so
/// the legend always matches the actual dot colours — there is no
/// separate list of colours to keep in sync.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: ScoreColorService.legendItems.map((item) {
        final (color, label) = item;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        );
      }).toList(),
    );
  }
}
