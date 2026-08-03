import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_helpers.dart';
import '../../data/task_model.dart';

/// A single task, shown as a Material 3 [Card].
///
/// There is no separate Tasks screen in this sprint — the Home Dashboard
/// is the only place tasks are shown — so, unlike `ObjectiveCard`, this
/// widget doesn't need a `showActions` toggle; Edit/Delete are always
/// present, as requested.
///
/// [linkedObjectiveTitle] is passed in already resolved to a string by
/// the caller (see `home_screen.dart`) — this widget never looks up an
/// Objective itself, so it has zero dependency on the Objectives
/// feature. It holds no state and calls no repository/provider.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.linkedObjectiveTitle,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  final Task task;
  final String? linkedObjectiveTitle;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
                  onChanged: (_) => onToggleComplete?.call(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? theme.colorScheme.outline
                              : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
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
                  _TaskPriorityChip(priority: task.priority),
                  _PointsChip(points: task.pointValue),
                  if (task.dueTime != null) _DueTimeChip(time: task.dueTime!),
                  if (linkedObjectiveTitle != null)
                    _LinkedObjectiveChip(title: linkedObjectiveTitle!),
                ],
              ),
            ),
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
        ),
      ),
    );
  }
}

// --- Small private display helpers -----------------------------------
// Scoped to this file, same reasoning as ObjectiveCard's private chips:
// purely about rendering, not part of the data model. Not shared with
// ObjectiveCard's private chip classes (those are private to that file)
// — a small, deliberate duplication that keeps the two features
// independently removable rather than cross-importing UI internals.

class _TaskPriorityChip extends StatelessWidget {
  const _TaskPriorityChip({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (priority) {
      TaskPriority.high => ('High', theme.colorScheme.error),
      TaskPriority.medium => ('Medium', Colors.orange),
      TaskPriority.low => ('Low', Colors.green),
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

class _DueTimeChip extends StatelessWidget {
  const _DueTimeChip({required this.time});
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.schedule_outlined, size: 16),
      label: Text(formatTime(time)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _LinkedObjectiveChip extends StatelessWidget {
  const _LinkedObjectiveChip({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.flag_circle_outlined, size: 16),
      label: Text(title, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
