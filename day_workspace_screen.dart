import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/utils/date_time_helpers.dart';
import '../../documents/data/document_model.dart';
import '../../documents/logic/daily_note_service.dart';
import '../../documents/logic/document_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../objectives/logic/objectives_provider.dart';
import '../../objectives/presentation/widgets/objective_card.dart';
import '../../score/logic/score_color_service.dart';
import '../../tasks/logic/tasks_provider.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../data/day_workspace_data.dart';
import '../logic/day_workspace_provider.dart';
class DayWorkspaceScreen extends ConsumerWidget {
  const DayWorkspaceScreen({super.key, required this.date});

  final DateTime date;

  Future<void> _handleOpenNote(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(documentRepositoryProvider);
      final vault = ref.read(activeVaultProvider).valueOrNull;
      if (vault == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No vault configured yet.')),
        );
        return;
      }
      final note = await DailyNoteService.getOrCreate(repo, date, vault);
      if (!context.mounted) return;
      context.push('/document', extra: note);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open daily note: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(dayWorkspaceProvider(date));

    return Scaffold(
      appBar: AppBar(title: Text(formatFullDate(date))),
      body: workspaceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load workspace',
            message: '$e',
          ),
        ),
        data: (data) => _WorkspaceBody(
            data: data,
            ref: ref,
            onOpenNote: () => _handleOpenNote(context, ref),
          ),
      ),
    );
  }
}

class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({
    required this.data,
    required this.ref,
    required this.onOpenNote,
  });

  final DayWorkspaceData data;
  final WidgetRef ref;
  final VoidCallback onOpenNote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ScoreCard(score: data.score),
            const SizedBox(height: 20),
            _DailyNoteSection(data: data, onOpenNote: onOpenNote),
            const SizedBox(height: 20),
            _TasksSection(data: data, ref: ref),
            const SizedBox(height: 20),
            _ObjectivesSection(data: data),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Score Card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final double? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (score == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.bar_chart_outlined),
              const SizedBox(width: 12),
              Text('No score recorded for this day.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    final color = ScoreColorService.colorForScore(score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: score! / 100,
              strokeWidth: 5,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Score',
                    style: theme.textTheme.titleMedium),
                Text(
                  '${score!.round()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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

// ── Daily Note Section ────────────────────────────────────────────────────────

class _DailyNoteSection extends StatelessWidget {
  const _DailyNoteSection({required this.data, required this.onOpenNote});
  final DayWorkspaceData data;
  final VoidCallback onOpenNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Daily Note'),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(
              data.hasDailyNote
                  ? data.dailyNote!.title
                  : 'No daily note yet',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              data.hasDailyNote ? 'Tap to open' : 'Tap to create',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            // Wired in the Internal Documents / Obsidian sprint.
            // The screen does not know or care which source backs it.
            onTap: onOpenNote,
          ),
        ),
      ],
    );
  }
}

// ── Tasks Section ─────────────────────────────────────────────────────────────

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.data, required this.ref});

  final DayWorkspaceData data;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(tasksProvider.notifier);
    final allObjectives = ref.read(objectivesProvider).valueOrNull ?? [];

    String? titleFor(String? id) => id == null
        ? null
        : allObjectives.where((o) => o.id == id).firstOrNull?.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Today's Tasks"),
        const SizedBox(height: 8),
        if (!data.isToday)
          const EmptyState(
            icon: Icons.history,
            title: 'Task history not yet available',
            message: 'Per-day task records will be added in a future sprint.',
          )
        else if (!data.hasTasks)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No tasks yet today',
          )
        else
          ...data.tasks.map((t) => TaskCard(
                task: t,
                linkedObjectiveTitle: titleFor(t.linkedObjectiveId),
                onToggleComplete: () {
                  notifier.toggleCompletion(t.id);
                },
                onEdit: () {},   // editing stays on Dashboard
                onDelete: () {}, // deleting stays on Dashboard
              )),
      ],
    );
  }
}

// ── Objectives Section ────────────────────────────────────────────────────────

class _ObjectivesSection extends StatelessWidget {
  const _ObjectivesSection({required this.data});

  final DayWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Linked Objectives'),
        const SizedBox(height: 8),
        if (!data.hasLinkedObjectives)
          const EmptyState(
            icon: Icons.flag_outlined,
            title: 'No linked objectives',
            message: 'Link a task to an objective to see it here.',
          )
        else
          ...data.linkedObjectives.map((o) =>
              ObjectiveCard(objective: o, showActions: false)),
      ],
    );
  }
}
