import 'package:uuid/uuid.dart';

import '../models/task.dart';

final _uuid = const Uuid();

final List<Task> mockTasks = [
  Task(
    id: _uuid.v4(),
    title: 'Set up CI/CD',
    description: 'Create GitHub Actions workflow for tests and formatting.',
    status: TaskStatus.todo,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Task(
    id: _uuid.v4(),
    title: 'Design task cards',
    description: 'Finalize card layout and hover states for the board.',
    status: TaskStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
  ),
  Task(
    id: _uuid.v4(),
    title: 'Add BLoC tests',
    description: 'Cover happy path and edge cases for TaskBoardCubit.',
    status: TaskStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(hours: 18)),
  ),
  Task(
    id: _uuid.v4(),
    title: 'Improve empty states',
    description: 'Add illustrations and helpful actions for new users.',
    status: TaskStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
  ),
  Task(
    id: _uuid.v4(),
    title: 'Release 0.1.0',
    description: 'Tag release and send patch notes to stakeholders.',
    status: TaskStatus.done,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
  ),
];

final List<Task> emptyTasks = [];

