import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/task_api_service.dart';
import '../models/task.dart';

class TaskBoardState extends Equatable {
  const TaskBoardState({
    required this.tasks,
    this.isLoading = false,
    this.error,
  });

  final List<Task> tasks;
  final bool isLoading;
  final String? error;

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

  TaskBoardState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) =>
      TaskBoardState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [tasks, isLoading, error];
}

class TaskBoardCubit extends Cubit<TaskBoardState> {
  TaskBoardCubit({
    List<Task> seedTasks = const [],
    TaskApiService? apiService,
  })  : _apiService = apiService ?? TaskApiService(),
        super(TaskBoardState(tasks: List<Task>.from(seedTasks)));

  final TaskApiService _apiService;

  Future<void> loadTasks() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final tasks = await _apiService.fetchAllTasks();
      emit(state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final task = await _apiService.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
      );
      final updated = [task, ...state.tasks];
      emit(state.copyWith(tasks: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final updatedTask = await _apiService.updateTask(
        taskId: task.id,
        title: task.title,
        description: task.description,
        status: task.status.value,
        dueDate: task.dueDate,
      );
      final updated = state.tasks
          .map((t) => t.id == task.id ? updatedTask : t)
          .toList();
      emit(state.copyWith(tasks: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> moveTask(String taskId, TaskStatus status) async {
    try {
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(status: status);
      await updateTask(updatedTask);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeTask(String taskId) async {
    try {
      await _apiService.deleteTask(taskId);
      final updated = state.tasks.where((task) => task.id != taskId).toList();
      emit(state.copyWith(tasks: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
