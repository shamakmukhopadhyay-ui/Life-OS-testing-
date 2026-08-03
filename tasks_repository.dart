import 'task_model.dart';

/// Abstract repository interface for the Tasks feature.
///
/// Mirrors the pattern established by ObjectivesRepository.
/// The Logic layer never imports a concrete implementation.
abstract class TasksRepository {
  Future<List<Task>> getAll();
  Future<void> insert(Task task);
  Future<void> update(Task task);
  Future<void> delete(String id);
}
