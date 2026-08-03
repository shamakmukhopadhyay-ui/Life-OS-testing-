import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../data/objective_model.dart';
import '../logic/objectives_provider.dart';
import 'widgets/objective_card.dart';
import 'widgets/objective_form_sheet.dart';

/// The full Objectives screen: Active and Completed objectives grouped
/// by status, with full Edit/Archive/Delete/create actions.
///
/// The body is gated by objectivesAsync.when() so the screen shows a
/// loading spinner while SQLite initialises on the first launch, and a
/// clear error message if the DB fails. Once data arrives the screen
/// renders identically to its pre-Sprint-6 appearance.
///
/// Archived objectives are not shown here — archivedObjectivesProvider
/// exists for a future dedicated Archive screen.
class ObjectivesScreen extends ConsumerWidget {
  const ObjectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectivesAsync = ref.watch(objectivesProvider);
    final notifier = ref.read(objectivesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Objectives')),
      body: objectivesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load objectives',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
        data: (_) {
          final active = ref.watch(activeObjectivesProvider);
          final completed = ref.watch(completedObjectivesProvider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'Active'),
              const SizedBox(height: 8),
              if (active.isEmpty)
                const EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No active objectives',
                  message: 'Tap the + button to create your first one.',
                )
              else
                ...active.map(
                  (o) => ObjectiveCard(
                    objective: o,
                    onToggleComplete: () {
                      notifier.toggleCompletion(o.id);
                    },
                    onEdit: () => _openEditSheet(context, notifier, o),
                    onArchive: () {
                      notifier.archiveObjective(o.id);
                    },
                    onDelete: () => _confirmDelete(context, notifier, o),
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Completed'),
              const SizedBox(height: 8),
              if (completed.isEmpty)
                const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Nothing completed yet',
                )
              else
                ...completed.map(
                  (o) => ObjectiveCard(
                    objective: o,
                    onToggleComplete: () {
                      notifier.toggleCompletion(o.id);
                    },
                    onEdit: () => _openEditSheet(context, notifier, o),
                    onArchive: () {
                      notifier.archiveObjective(o.id);
                    },
                    onDelete: () => _confirmDelete(context, notifier, o),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showObjectiveFormSheet(
          context: context,
          // Block lambda: notifier.addObjective returns Future<void>,
          // which is not directly assignable to void Function(Objective).
          onSubmit: (o) {
            notifier.addObjective(o);
          },
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    ObjectivesNotifier notifier,
    Objective objective,
  ) {
    showObjectiveFormSheet(
      context: context,
      existing: objective,
      onSubmit: (o) {
        notifier.updateObjective(o);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ObjectivesNotifier notifier,
    Objective objective,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete objective?'),
        content: Text(
          'This will permanently remove "${objective.title}". '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.deleteObjective(objective.id);
    }
  }
}
