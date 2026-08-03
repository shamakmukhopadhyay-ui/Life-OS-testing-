import 'objective_model.dart';
import 'objectives_repository.dart';

/// In-memory mock, preserved from before Sprint 6 for unit tests.
///
/// Inject via ProviderScope override to test without a real database:
/// ```dart
/// ProviderScope(
///   overrides: [
///     objectivesRepositoryProvider.overrideWithValue(
///       MockObjectivesRepository(),
///     ),
///   ],
///   child: const LifeOSApp(),
/// )
/// ```
///
/// NOT used by the running app after Sprint 6.
class MockObjectivesRepository implements ObjectivesRepository {
  @override
  Future<List<Objective>> getAll() async {
    final now = DateTime.now();
    return [
      Objective(
        id: '1',
        title: 'Get fit for summer',
        description:
            'Build a consistent workout habit and improve overall fitness.',
        category: ObjectiveCategory.health,
        priority: ObjectivePriority.high,
        pointValue: 100,
        status: ObjectiveStatus.active,
        targetDate: DateTime(now.year, 8, 1),
        linkedTasksTotal: 10,
        linkedTasksCompleted: 4,
      ),
      Objective(
        id: '2',
        title: 'Learn Flutter deeply',
        description:
            'Go beyond tutorials and build a real, production-quality app.',
        category: ObjectiveCategory.education,
        priority: ObjectivePriority.medium,
        pointValue: 80,
        status: ObjectiveStatus.active,
        linkedTasksTotal: 6,
        linkedTasksCompleted: 5,
      ),
      Objective(
        id: '3',
        title: 'Save a \$5,000 emergency fund',
        description:
            'Set aside money each month toward a financial safety net.',
        category: ObjectiveCategory.finance,
        priority: ObjectivePriority.high,
        pointValue: 120,
        status: ObjectiveStatus.active,
        targetDate: DateTime(now.year + 1, 1, 1),
        linkedTasksTotal: 12,
        linkedTasksCompleted: 3,
      ),
    ];
  }

  @override
  Future<void> insert(Objective objective) async {}

  @override
  Future<void> update(Objective objective) async {}

  @override
  Future<void> delete(String id) async {}
}
