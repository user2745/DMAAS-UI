import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';

class TaskBoardState extends Equatable {
  const TaskBoardState({required this.tasks});

  final List<Task> tasks;

  Map<TaskStatus, List<Task>> get groupedByStatus {
    final Map<TaskStatus, List<Task>> map = {
      for (final status in TaskStatus.values) status: <Task>[],
    };
    for (final task in tasks) {
      map[task.status]!.add(task);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return map;
  }

  TaskBoardState copyWith({List<Task>? tasks}) =>
      TaskBoardState(tasks: tasks ?? this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskBoardCubit extends Cubit<TaskBoardState> {
  TaskBoardCubit({List<Task> seedTasks = const []})
    : super(TaskBoardState(tasks: List<Task>.from(seedTasks)));

  void addTask(Task task) {
    final updated = [task, ...state.tasks];
    emit(state.copyWith(tasks: updated));
  }

  void updateTask(Task task) {
    final updated = state.tasks.map((t) => t.id == task.id ? task : t).toList();
    emit(state.copyWith(tasks: updated));
  }

  void moveTask(String taskId, TaskStatus status) {
    final updated = state.tasks
        .map((t) => t.id == taskId ? t.copyWith(status: status) : t)
        .toList();
    emit(state.copyWith(tasks: updated));
  }

  void removeTask(String taskId) {
    final updated = state.tasks.where((task) => task.id != taskId).toList();
    emit(state.copyWith(tasks: updated));
  }
}
