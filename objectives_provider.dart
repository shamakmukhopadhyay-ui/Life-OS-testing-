import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../data/objective_model.dart';
import '../data/objectives_repository.dart';
import '../data/sqlite_objectives_repository.dart';

/// Wires the active ObjectivesRepository implementation.
/// Override in tests with MockObjectivesRepository.
final objectivesRepositoryProvider = Provider<ObjectivesRepository>((ref) {
  return SqliteObjectivesRepository(ref.watch(databaseProvider));
});

/// Holds all objective state and mutations.
///
/// Migrated from Notifier to AsyncNotifier in Sprint 6 because all
/// repository operations are now async (SQLite I/O).
///
/// Every public method follows the same pattern:
///   1. Write the change to SQLite via the repository.
///   2. Reload the full list from SQLite into state.
///
/// Reloading after every write (rather than optimistically patching the
/// in-memory list) keeps state always consistent with the database and
/// naturally picks up any computed fields (e.g. linked task counts from
/// the subquery in SqliteObjectivesRepository.getAll).
class ObjectivesNotifier extends AsyncNotifier<List<Objective>> {
  @override
  Future<List<Objective>> build() => _load();

  Future<List<Objective>> _load() =>
      ref.read(objectivesRepositoryProvider).getAll();

  Future<void> addObjective(Objective objective) async {
    await ref.read(objectivesRepositoryProvider).insert(objective);
    state = await AsyncValue.guard(_load);
  }

  Future<void> updateObjective(Objective updated) async {
    assert(
      state.valueOrNull?.any((o) => o.id == updated.id) ?? false,
      'updateObjective: id "${updated.id}" not found in state.',
    );
    await ref.read(objectivesRepositoryProvider).update(updated);
    state = await AsyncValue.guard(_load);
  }

  Future<void> deleteObjective(String id) async {
    await ref.read(objectivesRepositoryProvider).delete(id);
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleCompletion(String id) async {
    final current =
        state.valueOrNull?.where((o) => o.id == id).firstOrNull;
    if (current == null || current.status == ObjectiveStatus.archived) return;
    final updated = current.copyWith(
      status: current.status == ObjectiveStatus.completed
          ? ObjectiveStatus.active
          : ObjectiveStatus.completed,
    );
    await ref.read(objectivesRepositoryProvider).update(updated);
    state = await AsyncValue.guard(_load);
  }

  Future<void> archiveObjective(String id) async {
    final current =
        state.valueOrNull?.where((o) => o.id == id).firstOrNull;
    if (current == null) return;
    await ref.read(objectivesRepositoryProvider)
        .update(current.copyWith(status: ObjectiveStatus.archived));
    state = await AsyncValue.guard(_load);
  }
}

final objectivesProvider =
    AsyncNotifierProvider<ObjectivesNotifier, List<Objective>>(
  ObjectivesNotifier.new,
);

// ── Derived providers ─────────────────────────────────────────────────────────
//
// These return plain List<Objective> (possibly empty during loading) by
// unwrapping AsyncValue via valueOrNull ?? []. This keeps every
// consuming widget structurally unchanged — they receive a List and render
// it. The loading/error UI gate lives at the screen level (objectivesAsync
// .when(...)) not at every individual widget.

final activeObjectivesProvider = Provider<List<Objective>>((ref) {
  return ref.watch(objectivesProvider).valueOrNull
          ?.where((o) => o.status == ObjectiveStatus.active)
          .toList() ??
      [];
});

final completedObjectivesProvider = Provider<List<Objective>>((ref) {
  return ref.watch(objectivesProvider).valueOrNull
          ?.where((o) => o.status == ObjectiveStatus.completed)
          .toList() ??
      [];
});

final archivedObjectivesProvider = Provider<List<Objective>>((ref) {
  return ref.watch(objectivesProvider).valueOrNull
          ?.where((o) => o.status == ObjectiveStatus.archived)
          .toList() ??
      [];
});
