import '../../documents/data/document_model.dart';
import '../../objectives/data/objective_model.dart';
import '../../tasks/data/task_model.dart';
import '../data/day_workspace_data.dart';

/// Assembles a [DayWorkspaceData] from already-loaded domain objects.
///
/// Pure Dart — no I/O, no Flutter, no Riverpod.
class DayWorkspaceService {
  DayWorkspaceService._();

  static DayWorkspaceData assemble({
    required DateTime date,
    required double? score,
    required List<Task> tasks,
    required List<Objective> objectives,
    Document? dailyNote, // null until document module is wired
  }) {
    final d = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final isToday = d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;

    final dayTasks = isToday ? tasks : const <Task>[];

    final linkedIds = dayTasks
        .where((t) => t.linkedObjectiveId != null)
        .map((t) => t.linkedObjectiveId!)
        .toSet();

    final linked = objectives
        .where((o) => linkedIds.contains(o.id))
        .toList();

    return DayWorkspaceData(
      date: d,
      isToday: isToday,
      score: score,
      tasks: dayTasks,
      linkedObjectives: linked,
      dailyNote: dailyNote,
    );
  }
}
