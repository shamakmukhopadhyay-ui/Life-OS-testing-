import 'task_model.dart';
import 'tasks_repository.dart';

/// In-memory mock, preserved from before Sprint 6 for unit tests.
/// NOT used by the running app after Sprint 6.
class MockTasksRepository implements TasksRepository {
  @override
  Future<List<Task>> getAll() async {
    final now = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);

    return [
      Task(
        id: '1',
        title: 'Morning workout',
        description: '30 minutes of cardio and stretching.',
        linkedObjectiveId: '1',
        pointValue: 15,
        priority: TaskPriority.high,
        dueTime: at(7, 0),
        isCompleted: true,
      ),
      Task(
        id: '2',
        title: 'Read Flutter/Riverpod docs',
        linkedObjectiveId: '2',
        pointValue: 10,
        priority: TaskPriority.medium,
        dueTime: at(20, 0),
      ),
      Task(
        id: '3',
        title: 'Transfer money to savings',
        description: 'Automate a \$200 transfer.',
        linkedObjectiveId: '3',
        pointValue: 20,
        priority: TaskPriority.high,
      ),
      Task(
        id: '4',
        title: 'Buy groceries',
        description: 'Milk, eggs, vegetables.',
        pointValue: 5,
        priority: TaskPriority.low,
        dueTime: at(18, 30),
      ),
    ];
  }

  @override
  Future<void> insert(Task task) async {}

  @override
  Future<void> update(Task task) async {}

  @override
  Future<void> delete(String id) async {}
}
