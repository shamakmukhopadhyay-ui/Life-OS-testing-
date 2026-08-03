/// The core Objective entity, plus its supporting enums.
///
/// Deliberately pure Dart — no Flutter import here. This keeps the model
/// reusable by the data layer (mock now, SQLite later), the logic layer,
/// and any future feature (including future AI features, per the
/// requirement to keep this referenceable) without dragging in UI code.
/// Anything about *how* an objective is displayed (colors, icons) lives
/// in the presentation layer instead — see `objective_card.dart`.

/// How important the objective is to the user.
enum ObjectivePriority { low, medium, high }

/// Where the objective is in its lifecycle.
///
/// - [active]: currently being worked on.
/// - [completed]: finished, kept visible for reference/history.
/// - [archived]: set aside, no longer active but not deleted.
enum ObjectiveStatus { active, completed, archived }

/// Broad life-area grouping, mirroring the kind of categories a personal
/// goal-tracking app typically needs. Kept as a fixed enum (rather than
/// free text) so the UI can render consistent chips/colors.
enum ObjectiveCategory { personal, health, career, finance, education, other }

class Objective {
  const Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.pointValue,
    required this.status,
    this.targetDate,
    this.linkedTasksTotal = 0,
    this.linkedTasksCompleted = 0,
  });

  final String id;
  final String title;
  final String description;
  final ObjectiveCategory category;
  final ObjectivePriority priority;
  final int pointValue;
  final ObjectiveStatus status;

  /// Optional — not every objective needs a deadline.
  final DateTime? targetDate;

  /// How many tasks are currently linked to this objective, and how many
  /// of those are complete. In this phase these are plain mock numbers
  /// set on sample data (there is no real Tasks feature yet to link to).
  /// Once Tasks exists, these will be computed from real linked-task
  /// records instead of stored directly on the objective — the [progress]
  /// getter below is written so that swap won't change any calling code.
  final int linkedTasksTotal;
  final int linkedTasksCompleted;

  /// Progress toward this objective, from 0.0 to 1.0, based on completed
  /// linked tasks. Returns 0 if no tasks are linked yet.
  double get progress =>
      linkedTasksTotal == 0 ? 0.0 : linkedTasksCompleted / linkedTasksTotal;

  Objective copyWith({
    String? title,
    String? description,
    ObjectiveCategory? category,
    ObjectivePriority? priority,
    int? pointValue,
    ObjectiveStatus? status,
    DateTime? targetDate,
    bool clearTargetDate = false,
    int? linkedTasksTotal,
    int? linkedTasksCompleted,
  }) {
    return Objective(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      pointValue: pointValue ?? this.pointValue,
      status: status ?? this.status,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      linkedTasksTotal: linkedTasksTotal ?? this.linkedTasksTotal,
      linkedTasksCompleted: linkedTasksCompleted ?? this.linkedTasksCompleted,
    );
  }
}
