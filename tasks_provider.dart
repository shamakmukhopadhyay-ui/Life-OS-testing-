import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../data/task_model.dart';
import '../data/tasks_repository.dart';
import '../data/sqlite_tasks_repository.dart';
// Cross-feature import — justified and documented in ARCHITECTURE.md:
// TasksNotifier invalidates objectivesProvider after every mutation so
// that linked task progress counts (computed via SQL subquery in
// SqliteObjectivesRepository.getAll) stay accurate without polling.
import '../../objectives/logic/objectives_provider.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return SqliteTasksRepository(ref.watch(databaseProvider));
});

/// Holds all task state and mutations.
///
/// Migrated from Notifier to AsyncNotifier in Sprint 6.
/// Same write-then-reload pattern as ObjectivesNotifier.
///
/// Additionally calls ref.invalidate(objectivesProvider) after every
/// mutation so the linked objective's progress bar updates immediately:
/// the next objectives load will re-run the correlated subqueries in
/// SqliteObjectivesRepository.getAll and pick up the new task counts.
class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() => _load();

  Future<List<Task>> _load() =>
      ref.read(tasksRepositoryProvider).getAll();

  Future<void> addTask(Task task) async {
    await ref.read(tasksRepositoryProvider).insert(task);
    state = await AsyncValue.guard(_load);
    ref.invalidate(objectivesProvider);
  }

  Future<void> updateTask(Task updated) async {
    assert(
      state.valueOrNull?.any((t) => t.id == updated.id) ?? false,
      'updateTask: id "${updated.id}" not found in state.',
    );
    await ref.read(tasksRepositoryProvider).update(updated);
    state = await AsyncValue.guard(_load);
    ref.invalidate(objectivesProvider);
  }

  Future<void> deleteTask(String id) async {
    await ref.read(tasksRepositoryProvider).delete(id);
    state = await AsyncValue.guard(_load);
    ref.invalidate(objectivesProvider);
  }

  Future<void> toggleCompletion(String id) async {
    final current =
        state.valueOrNull?.where((t) => t.id == id).firstOrNull;
    if (current == null) return;
    await ref.read(tasksRepositoryProvider)
        .update(current.copyWith(isCompleted: !current.isCompleted));
    state = await AsyncValue.guard(_load);
    // This is the most important invalidation: toggling a task's
    // completion directly changes its linked objective's progress bar.
    ref.invalidate(objectivesProvider);
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);
