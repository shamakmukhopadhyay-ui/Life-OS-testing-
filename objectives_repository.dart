import 'objective_model.dart';

/// Abstract repository interface for the Objectives feature.
///
/// The Logic layer (ObjectivesNotifier) only ever imports this type —
/// never a concrete class. Swapping implementations is done at the
/// provider level in objectives_provider.dart, so neither the notifier
/// nor any Presentation code needs to change when the implementation
/// changes (e.g. SQLite to cloud, or concrete to mock for tests).
///
/// All operations are Future-returning because the SQLite implementation
/// performs I/O. The mock implementation wraps synchronous values in
/// Future.value so callers are never aware which implementation is live.
abstract class ObjectivesRepository {
  /// Returns every objective, with Objective.linkedTasksTotal and
  /// Objective.linkedTasksCompleted populated from the tasks table.
  Future<List<Objective>> getAll();

  /// Persists a new objective. objective.id must be unique in the store.
  Future<void> insert(Objective objective);

  /// Overwrites every mutable field of an existing objective row.
  /// objective.id must already exist.
  Future<void> update(Objective objective);

  /// Permanently removes the objective row with id.
  ///
  /// Tasks whose Task.linkedObjectiveId == id are NOT deleted here.
  /// They become orphaned — their link points to a non-existent
  /// objective. Handled defensively in the task form sheet (orphan
  /// detection from the bug-fix sprint). A cascade/nullify policy will
  /// be confirmed in a future sprint.
  Future<void> delete(String id);
}
