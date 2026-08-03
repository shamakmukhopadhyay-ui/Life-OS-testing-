import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/logic/document_provider.dart';
import '../../objectives/logic/objectives_provider.dart';
import '../../score/logic/day_scores_provider.dart';
import '../../tasks/logic/tasks_provider.dart';
import '../data/day_workspace_data.dart';
import 'day_workspace_service.dart';

final dayWorkspaceProvider =
    FutureProvider.family<DayWorkspaceData, DateTime>((ref, date) async {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  final objectives = ref.watch(objectivesProvider).valueOrNull ?? [];

  // Use the shared dayScoresRepositoryProvider — removed duplicate local provider.
  final repo = ref.read(dayScoresRepositoryProvider);
  final monthScores = await repo.getScoresForMonth(date);
  final dayKey = DateTime(date.year, date.month, date.day);
  final score = monthScores[dayKey];

  final dailyNote = ref.watch(dailyNoteProvider(date)).valueOrNull;

  return DayWorkspaceService.assemble(
    date: date,
    score: score,
    tasks: tasks,
    objectives: objectives,
    dailyNote: dailyNote,
  );
});
