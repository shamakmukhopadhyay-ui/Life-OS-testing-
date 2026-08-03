import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../objectives/logic/objectives_provider.dart';
import '../../tasks/logic/tasks_provider.dart';
import '../data/daily_score_result.dart';
import 'score_service.dart';

/// Produces today's [DailyScoreResult] reactively.
///
/// This is a plain [Provider] (not Async) because [ScoreService.calculate]
/// is synchronous — it does no I/O, only arithmetic. The async work has
/// already happened inside [objectivesProvider] and [tasksProvider];
/// by the time this provider reads them they are already [AsyncValue]s
/// whose data is unwrapped via [AsyncValue.valueOrNull].
///
/// Reactivity: any change to objectives or tasks (CRUD, toggle, archive)
/// causes [objectivesProvider] or [tasksProvider] to emit a new state,
/// which triggers this provider to recompute automatically. The Dashboard
/// always shows a score consistent with the current SQLite data.
///
/// Empty lists are handled by [ScoreService] — it returns
/// [DailyScoreResult.empty] rather than dividing by zero, so the
/// Dashboard renders safely before any data has been entered.
final dailyScoreProvider = Provider<DailyScoreResult>((ref) {
  // Unwrap AsyncValue with valueOrNull so this provider stays synchronous.
  // While data is still loading (first launch), both lists are empty and
  // ScoreService returns DailyScoreResult.empty.
  final objectives = ref.watch(objectivesProvider).valueOrNull ?? [];
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];

  return ScoreService.calculate(
    objectives: objectives,
    tasks: tasks,
  );
});
