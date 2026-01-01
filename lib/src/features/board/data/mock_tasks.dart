import 'package:uuid/uuid.dart';

import '../models/task.dart';

final _uuid = const Uuid();

final List<Task> mockTasks = [
  Task(
    id: _uuid.v4(),
    title: 'Set up CI/CD',
    description: 'Create GitHub Actions workflow for tests and formatting.',
    status: TaskStatus.backlog,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    assignee: 'Amira',
  ),
  Task(
    id: _uuid.v4(),
    title: 'Design task cards',
    description: 'Finalize card layout and hover states for the board.',
    status: TaskStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    assignee: 'Luis',
  ),
  Task(
    id: _uuid.v4(),
    title: 'Add BLoC tests',
    description: 'Cover happy path and edge cases for TaskBoardCubit.',
    status: TaskStatus.review,
    createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    assignee: 'Priya',
  ),
  Task(
    id: _uuid.v4(),
    title: 'Improve empty states',
    description: 'Add illustrations and helpful actions for new users.',
    status: TaskStatus.review,
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    assignee: 'Wei',
  ),
  Task(
    id: _uuid.v4(),
    title: 'Release 0.1.0',
    description: 'Tag release and send patch notes to stakeholders.',
    status: TaskStatus.done,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    assignee: 'Maya',
  ),
];
