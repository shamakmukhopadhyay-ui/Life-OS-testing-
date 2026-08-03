import '../../documents/data/document_model.dart';
import '../../objectives/data/objective_model.dart';
import '../../tasks/data/task_model.dart';

/// Immutable snapshot of all data needed to render one day's workspace.
///
/// Assembled by [DayWorkspaceService]; consumed by [DayWorkspaceScreen].
/// Pure Dart — no Flutter or Riverpod imports.
class DayWorkspaceData {
  const DayWorkspaceData({
    required this.date,
    required this.isToday,
    this.score,
    required this.tasks,
    required this.linkedObjectives,
    this.dailyNote,
  });

  final DateTime date;
  final bool isToday;
  final double? score;
  final List<Task> tasks;
  final List<Objective> linkedObjectives;

  /// The daily note document for this date, or null when no document
  /// module is configured yet. Populated by [dailyNoteProvider] once
  /// an implementation of [DocumentRepository] is registered.
  final Document? dailyNote;

  bool get hasScore => score != null;
  bool get hasTasks => tasks.isNotEmpty;
  bool get hasLinkedObjectives => linkedObjectives.isNotEmpty;
  bool get hasDailyNote => dailyNote != null;
}
