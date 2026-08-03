import 'package:flutter/material.dart';

import '../../data/objective_model.dart';

/// A single objective, shown as a Material 3 [Card].
///
/// Used in two places:
/// - The Objectives screen, with [showActions] true — full card with
///   Edit/Archive/Delete buttons.
/// - The Home Dashboard's "Today's Objectives" preview, with
///   [showActions] false — same visual card, just without the action
///   row, since editing/archiving/deleting from the dashboard preview
///   isn't part of what was requested.
///
/// This widget holds no state and calls no repository/provider itself —
/// every callback is supplied by whoever places it, keeping this a pure
/// Presentation-layer widget.
class ObjectiveCard extends StatelessWidget {
  const ObjectiveCard({
    super.key,
    required this.objective,
    this.onToggleComplete,
    this.onEdit,
    this.onArchive,
    this.onDelete,
    this.showActions = true,
  });

  final Objective objective;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = objective.status == ObjectiveStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      // Completed objectives get a visibly quieter card background, on
      // top of the existing strikethrough title — the checkmark itself
      // comes for free from Checkbox's built-in checked appearance.
      color: isCompleted ? theme.colorScheme.surfaceContainerLow : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isCompleted,
                  onChanged: objective.status == ObjectiveStatus.archived
                      ? null
                      : (_) => onToggleComplete?.call(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        objective.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? theme.colorScheme.outline
                              : null,
                        ),
                      ),
                      if (objective.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          objective.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _CategoryChip(category: objective.category),
                  _PriorityChip(priority: objective.priority),
                  _PointsChip(points: objective.pointValue),
                  if (objective.targetDate != null)
                    _TargetDateChip(date: objective.targetDate!),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: objective.progress,
                minHeight: 6,
                // Muted color once completed, so a full bar doesn't
                // visually compete with the primary color used by
                // still-active objectives.
                color: isCompleted ? theme.colorScheme.outline : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${objective.linkedTasksCompleted} of '
              '${objective.linkedTasksTotal} linked tasks complete',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (showActions) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Archive'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Small private display helpers -----------------------------------
// Kept private to this file since they're purely about how to render an
// Objective's enum fields (colors/labels), not part of the data model
// itself — the model stays plain Dart with no UI concerns.

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final ObjectiveCategory category;

  static const _labels = {
    ObjectiveCategory.personal: 'Personal',
    ObjectiveCategory.health: 'Health',
    ObjectiveCategory.career: 'Career',
    ObjectiveCategory.finance: 'Finance',
    ObjectiveCategory.education: 'Education',
    ObjectiveCategory.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_labels[category] ?? 'Other'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final ObjectivePriority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (priority) {
      ObjectivePriority.high => ('High', theme.colorScheme.error),
      ObjectivePriority.medium => ('Medium', Colors.orange),
      ObjectivePriority.low => ('Low', Colors.green),
    };
    return Chip(
      avatar: Icon(Icons.flag, size: 16, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _PointsChip extends StatelessWidget {
  const _PointsChip({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.star, size: 16),
      label: Text('$points pts'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _TargetDateChip extends StatelessWidget {
  const _TargetDateChip({required this.date});
  final DateTime date;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${_months[date.month - 1]} ${date.day}, ${date.year}';
    return Chip(
      avatar: const Icon(Icons.event_outlined, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
