import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/id_generator.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/placeholder_card.dart';
import '../../core/widgets/section_header.dart';
import '../../features/documents/data/document_model.dart';
import '../../features/documents/logic/daily_note_service.dart';
import '../../features/documents/logic/document_provider.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/objectives/logic/objectives_provider.dart';
import '../../features/objectives/presentation/widgets/objective_card.dart';
import '../../features/quick_clipboard/presentation/widgets/quick_clipboard_card.dart';
import '../../features/tasks/data/task_model.dart';
import '../../features/tasks/logic/tasks_provider.dart';
import '../../features/tasks/presentation/widgets/task_card.dart';
import '../../features/tasks/presentation/widgets/task_form_sheet.dart';
import '../../features/score/logic/day_scores_provider.dart';
import '../../features/score/logic/score_provider.dart';
import '../../features/today/presentation/today_screen.dart';
import 'widgets/ai_bubble_button.dart';
import 'widgets/calendar_preview_card.dart';
import 'widgets/daily_progress_card.dart';
import 'widgets/greeting_header.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/remaining_summary_row.dart';

/// LifeOS app shell: bottom-nav tabs for Home, Today, Learn, and Library.
///
/// LifeOS V2-01 (App Shell Migration): this class now owns tab-switching
/// via an `IndexedStack` — previously only "Dashboard" ever rendered,
/// with the other three destinations purely changing which icon was
/// highlighted. Home's own content (below) is completely unchanged from
/// before this sprint:
/// - "Today's Objectives" reads real (mock-data-backed) state from the
///   Objectives feature via [activeObjectivesProvider]. Editing/deleting
///   from this preview is intentionally not offered (`showActions:
///   false`); use "See all" to reach the full screen.
/// - "Remaining Tasks" (renamed from "Today's Tasks" this sprint; the
///   underlying data/logic is untouched) reads real (mock-data-backed)
///   state from the Tasks feature via [tasksProvider]. There is no
///   separate Tasks screen yet, so full Edit/Delete are shown right
///   here, unlike the lighter Objectives preview above.
/// - The FAB opens the "New Task" form — now shown only on the Home tab
///   (`_navIndex == 0`), since a floating "add task" button doesn't make
///   sense while looking at Today, Learn, or Library. It sits alongside
///   the new [AiBubbleButton], which — unlike the task FAB — is visible
///   on every tab.
/// - [DailyProgressCard] is still driven by [dailyScoreProvider].
/// - Today, Learn, and Library are this sprint's new placeholder
///   screens (see their own files) — no business logic added here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  /// Which tab to open on. Lets the new `/home` `/today` `/learn`
  /// `/library` routes (V2-01 Task 8) land on a specific tab; `/`
  /// keeps working unchanged since this defaults to Home (0).
  final int initialIndex;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _navIndex = widget.initialIndex;

  static const _tabTitles = ['Home', 'Today', 'Learn', 'Library'];

  @override
  Widget build(BuildContext context) {
    final activeObjectives = ref.watch(activeObjectivesProvider);
    final objectivesNotifier = ref.read(objectivesProvider.notifier);
    // V2-02 Task 3: "Remaining Tasks" must show incomplete tasks only —
    // tasksProvider itself returns every task, completed or not, so the
    // filter belongs here at the point of use, not in the provider
    // (which other, non-"remaining" consumers may still want unfiltered).
    final tasks = (ref.watch(tasksProvider).valueOrNull ?? [])
        .where((t) => !t.isCompleted)
        .toList();
    final tasksNotifier = ref.read(tasksProvider.notifier);

    // Persist today's score to SQLite whenever it changes so the
    // Calendar Heatmap can display historical scores.
    ref.listen<DailyScoreResult>(dailyScoreProvider, (previous, next) {
      if (next.totalPoints == 0) return; // nothing meaningful to store
      ref
          .read(dayScoresRepositoryProvider)
          .upsertForDate(DateTime.now(), next);
    });

    // Resolves a task's optional linkedObjectiveId into a display title.
    // This is the one place Home crosses from Tasks into Objectives data
    // — done here, at the Presentation layer, rather than inside either
    // feature's model or repository, so neither feature depends on the
    // other's data layer.
    final allObjectives = ref.watch(objectivesProvider).valueOrNull ?? [];
    String? linkedTitleFor(String? objectiveId) {
      if (objectiveId == null) return null;
      for (final o in allObjectives) {
        if (o.id == objectiveId) return o.title;
      }
      return null;
    }

    // Score — watched here so the card rebuilds on any task/objective change.
    final dailyScore = ref.watch(dailyScoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_navIndex]),
        actions: [
          if (_navIndex == 0)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                // Caps content width on tablets/desktop so cards don't stretch
                // into an unreadably wide single column. On phones this has
                // no visible effect since screens are narrower than 640.
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const GreetingHeader(),
                    const SizedBox(height: 20),
                    DailyProgressCard(score: dailyScore),
                    const SizedBox(height: 8),
                    RemainingSummaryRow(
                      remainingObjectives: activeObjectives.length,
                      remainingTasks: tasks.length,
                    ),
                    const SizedBox(height: 16),
                    const CalendarPreviewCard(),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: "Today's Objectives",
                      trailing: TextButton(
                        onPressed: () => context.push('/objectives'),
                        child: const Text('See all'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activeObjectives.isEmpty)
                      const EmptyState(
                        icon: Icons.flag_outlined,
                        title: 'No active objectives yet',
                        message: 'Tap "See all" to create one.',
                      )
                    else
                      ...activeObjectives.map(
                        (objective) => ObjectiveCard(
                          objective: objective,
                          showActions: false,
                          onToggleComplete: () { objectivesNotifier.toggleCompletion(objective.id); },
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Renamed from "Today's Tasks" (V2-01) — same
                    // underlying tasksProvider data, unchanged.
                    const SectionHeader(title: 'Remaining Tasks'),
                    const SizedBox(height: 8),
                    if (tasks.isEmpty)
                      const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No tasks yet',
                        message: 'Tap the + button to add your first task.',
                      )
                    else
                      ...tasks.map(
                        (task) => TaskCard(
                          task: task,
                          linkedObjectiveTitle:
                              linkedTitleFor(task.linkedObjectiveId),
                          onToggleComplete: () { tasksNotifier.toggleCompletion(task.id); },
                          onEdit: () => showTaskFormSheet(
                            context: context,
                            existing: task,
                            onSubmit: (t) { tasksNotifier.updateTask(t); },
                          ),
                          onDelete: () => _confirmDeleteTask(
                            context,
                            tasksNotifier,
                            task,
                          ),
                        ),
                      ),
                    // Quick Clipboard (V2-02 Task 4) — now a real,
                    // functional widget, replacing V2-01's placeholder.
                    const SizedBox(height: 24),
                    const QuickClipboardCard(),
                    const SizedBox(height: 4),
                    PlaceholderCard(
                      icon: Icons.center_focus_strong_outlined,
                      title: 'Focus Mode',
                      trailing: OutlinedButton(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text('Focus Mode is coming soon.'),
                          ),
                        ),
                        child: const Text('Start Session'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const PlaceholderCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI Suggestions',
                      subtitle: 'AI suggestions will appear here.',
                    ),
                    const SizedBox(height: 4),
                    QuickActionsCard(
                      onNewTask: () => showTaskFormSheet(
                        context: context,
                        onSubmit: (t) { tasksNotifier.addTask(t); },
                      ),
                      onNewNote: () => _startNewNote(context, ref),
                      onTodaysNote: () => _openTodaysNote(context, ref),
                    ),
                    // Extra bottom space so the last card isn't crowded by
                    // the floating action button / nav bar.
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          const TodayScreen(),
          const LearnScreen(),
          const LibraryScreen(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiBubbleButton(),
          // "Add task" only makes sense while looking at Home's own
          // task list — shown only on that tab (V2-01).
          if (_navIndex == 0) ...[
            const SizedBox(height: 12),
            FloatingActionButton(
              onPressed: () => showTaskFormSheet(
                context: context,
                onSubmit: (t) { tasksNotifier.addTask(t); },
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

/// Shows a confirmation dialog before deleting a task — the same safety
/// pattern already used for deleting an objective on the Objectives
/// screen, kept consistent here even though it wasn't explicitly
/// requested for tasks.
Future<void> _confirmDeleteTask(
  BuildContext context,
  TasksNotifier notifier,
  Task task,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete task?'),
      content: Text(
        'This will permanently remove "${task.title}". '
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
    notifier.deleteTask(task.id);
  }
}

/// "New Note" (V2-02 Task 6) — creates a blank, unsaved [Document] and
/// opens it in the existing editor. Deliberately does not call
/// `documentsProvider.notifier.createDocument` first: an untouched
/// blank note the user immediately backs out of shouldn't leave behind
/// an empty file. The editor's own autosave (unchanged, reused as-is)
/// persists it the moment there's real content to save — the same
/// upsert-on-save behavior every document's first save already relies
/// on, so nothing new is needed for a brand-new path to work correctly.
Future<void> _startNewNote(BuildContext context, WidgetRef ref) async {
  final vault = ref.read(activeVaultProvider).valueOrNull;
  if (vault == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No vault configured yet.')),
    );
    return;
  }
  final now = DateTime.now();
  final note = Document(
    path: '${generateLocalId()}.md',
    title: 'Untitled',
    content: '',
    vaultId: vault.id,
    createdAt: now,
    updatedAt: now,
  );
  context.push('/document', extra: note);
}

/// "Today's Note" (V2-02 Task 6) — reuses [DailyNoteService.getOrCreate]
/// exactly as `day_workspace_screen.dart` already does for the same
/// purpose, rather than a second implementation of "find or create
/// today's daily note."
Future<void> _openTodaysNote(BuildContext context, WidgetRef ref) async {
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
    final note = await DailyNoteService.getOrCreate(
      repo,
      DateTime.now(),
      vault,
    );
    if (!context.mounted) return;
    context.push('/document', extra: note);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Could not open today's note: $e")),
    );
  }
}
