/// The core Task entity, plus its priority enum.
///
/// Pure Dart, no Flutter import — same discipline as the Objectives
/// feature's `Objective` model. The optional link to an objective is
/// stored as a plain [linkedObjectiveId] string, not an `Objective`
/// object: this file does not import anything from the Objectives
/// feature, so Tasks and Objectives remain independently removable.
/// Resolving that id into a display title is a Presentation-layer
/// concern (see `home_screen.dart`), not a Data-layer one.

enum TaskPriority { low, medium, high }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.pointValue,
    required this.priority,
    this.description,
    this.linkedObjectiveId,
    this.dueTime,
    this.isCompleted = false,
  });

  final String id;
  final String title;

  /// Optional — not every task needs a description.
  final String? description;

  /// Optional — the id of an Objective this task contributes toward, or
  /// null if this task isn't linked to any objective. Deliberately just
  /// an id, not an `Objective` reference (see file doc comment above).
  final String? linkedObjectiveId;

  final int pointValue;

  /// Optional — a specific time today the task is due. Stored as a full
  /// [DateTime] (kept on today's date) rather than a Flutter `TimeOfDay`
  /// so this model stays Flutter-free; formatting for display happens in
  /// `core/utils/date_time_helpers.dart`.
  final DateTime? dueTime;

  final TaskPriority priority;
  final bool isCompleted;

  Task copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    String? linkedObjectiveId,
    bool clearLinkedObjectiveId = false,
    int? pointValue,
    DateTime? dueTime,
    bool clearDueTime = false,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      linkedObjectiveId: clearLinkedObjectiveId
          ? null
          : (linkedObjectiveId ?? this.linkedObjectiveId),
      pointValue: pointValue ?? this.pointValue,
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
