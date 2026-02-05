import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks_list/models/field.dart';
import '../data/task_api_service.dart';
import '../../tasks_list/data/field_api_service.dart';
import '../models/task.dart';

class TaskBoardState extends Equatable {
  const TaskBoardState({
    required this.tasks,
    this.fields = const [],
    this.isLoading = false,
    this.error,
    this.isReorderInFlight = false,
  });

  final List<Task> tasks;
  final List<Field> fields;
  final bool isLoading;
  final String? error;
  final bool isReorderInFlight;

  Map<TaskStatus, List<Task>> get groupedByStatus {
    final Map<TaskStatus, List<Task>> map = {
      for (final status in TaskStatus.values) status: <Task>[],
    };
    for (final task in tasks) {
      map[task.status]!.add(task);
    }
    for (final entry in map.entries) {
      // Sort by order ascending, then by createdAt descending
      entry.value.sort((a, b) {
        final orderComparison = a.order.compareTo(b.order);
        if (orderComparison != 0) return orderComparison;
        return b.createdAt.compareTo(a.createdAt);
      });
    }
    return map;
  }

  TaskBoardState copyWith({
    List<Task>? tasks,
    List<Field>? fields,
    bool? isLoading,
    String? error,
    bool? isReorderInFlight,
  }) =>
      TaskBoardState(
        tasks: tasks ?? this.tasks,
        fields: fields ?? this.fields,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isReorderInFlight: isReorderInFlight ?? this.isReorderInFlight,
      );

  @override
  List<Object?> get props => [tasks, fields, isLoading, error, isReorderInFlight];
}

class TaskBoardCubit extends Cubit<TaskBoardState> {
  TaskBoardCubit({
    List<Task> seedTasks = const [],
    required TaskApiService apiService,
    required FieldApiService fieldApiService,
  })  : _apiService = apiService,
        _fieldApiService = fieldApiService,
        super(TaskBoardState(tasks: List<Task>.from(seedTasks))) {
    _loadInitialData();
  }

  final TaskApiService _apiService;
  final FieldApiService _fieldApiService;
  Timer? _reorderDebounceTimer;
  final Set<TaskStatus> _affectedStatuses = {};

  Future<void> _loadInitialData() async {
    try {
      final fields = await _fieldApiService.fetchFields();
      emit(state.copyWith(fields: fields));
    } catch (e) {
      // Silently fail - fields are optional for display
    }
  }

  Future<void> loadFields() async {
    try {
      final fields = await _fieldApiService.fetchFields();
      emit(state.copyWith(fields: fields));
    } catch (e) {
      // Silently fail - fields are optional for display
    }
  }

  @override
  Future<void> close() {
    _reorderDebounceTimer?.cancel();
    return super.close();
  }

  Future<void> loadTasks() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final tasks = await _apiService.fetchAllTasks();
      final fields = await _fieldApiService.fetchFields();
      emit(state.copyWith(tasks: tasks, fields: fields, isLoading: false));
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
    Map<String, Object?>? fieldValues,
  }) async {
    try {
      final task = await _apiService.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        fieldValues: fieldValues,
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
        order: task.order,
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

  Future<void> reorderTask({
    required String taskId,
    required TaskStatus toStatus,
    required int toIndex,
  }) async {
    try {
      // Store previous state for rollback (in case needed for error handling)
      
      // Get the task being moved
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      final fromStatus = task.status;
      
      // Track affected statuses
      _affectedStatuses.add(fromStatus);
      _affectedStatuses.add(toStatus);
      
      // Optimistically update local state
      List<Task> updatedTasks = List<Task>.from(state.tasks);
      
      // Remove task from old position
      updatedTasks.removeWhere((t) => t.id == taskId);
      
      // Insert the task at the target index
      final movedTask = task.copyWith(status: toStatus);
      
      // Reassign order values for affected tasks
      final reorderedTasks = _reassignOrderValues(
        allTasks: updatedTasks,
        taskToInsert: movedTask,
        targetStatus: toStatus,
        insertIndex: toIndex,
      );
      
      // Emit optimistic state
      emit(state.copyWith(
        tasks: reorderedTasks,
        isReorderInFlight: true,
        error: null,
      ));
      
      // Debounce server sync
      _debounceServerSync();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Reassigns order values for all tasks, inserting taskToInsert at insertIndex in targetStatus
  List<Task> _reassignOrderValues({
    required List<Task> allTasks,
    required Task taskToInsert,
    required TaskStatus targetStatus,
    required int insertIndex,
  }) {
    final result = List<Task>.from(allTasks);
    
    // Get all tasks in target status
    final tasksInTarget = result
        .where((t) => t.status == targetStatus)
        .toList();
    
    // Remove them from result
    result.removeWhere((t) => t.status == targetStatus);
    
    // Insert the moved task at the target index
    tasksInTarget.insert(insertIndex.clamp(0, tasksInTarget.length), taskToInsert);
    
    // Reassign order values (0, 1, 2, ...)
    for (int i = 0; i < tasksInTarget.length; i++) {
      tasksInTarget[i] = tasksInTarget[i].copyWith(order: i);
    }
    
    // For other affected status, also reassign order values
    for (final status in _affectedStatuses) {
      if (status != targetStatus) {
        final tasksInStatus = result
            .where((t) => t.status == status)
            .toList();
        
        result.removeWhere((t) => t.status == status);
        
        for (int i = 0; i < tasksInStatus.length; i++) {
          tasksInStatus[i] = tasksInStatus[i].copyWith(order: i);
        }
        
        result.addAll(tasksInStatus);
      }
    }
    
    // Add back the reordered tasks in target status
    result.addAll(tasksInTarget);
    
    return result;
  }

  void _debounceServerSync() {
    // Cancel existing timer
    _reorderDebounceTimer?.cancel();
    
    // Set new 5-second timer
    _reorderDebounceTimer = Timer(const Duration(seconds: 5), () {
      _syncReorderedTasks();
    });
  }

  Future<void> _syncReorderedTasks() async {
    try {
      // Collect all tasks from affected statuses
      final tasksToSync = state.tasks
          .where((t) => _affectedStatuses.contains(t.status))
          .toList();
      
      // Call reorder endpoint
      if (tasksToSync.isNotEmpty) {
        final taskIds = tasksToSync.map((t) => t.id).toList();
        await _apiService.reorderTasks(taskIds);
      }
      
      // Clear affected statuses and set in-flight to false
      _affectedStatuses.clear();
      emit(state.copyWith(isReorderInFlight: false));
    } catch (e) {
      // On error, resync affected columns from server
      await _resyncAffectedColumns();
      emit(state.copyWith(
        error: 'Reorder failed: ${e.toString()}',
        isReorderInFlight: false,
      ));
    }
  }

  Future<void> _resyncAffectedColumns() async {
    try {
      // Fetch all tasks from server
      final allTasks = await _apiService.fetchAllTasks();
      
      // Keep tasks from non-affected statuses, replace affected ones
      final preservedTasks = state.tasks
          .where((t) => !_affectedStatuses.contains(t.status))
          .toList();
      
      final affectedTasks = allTasks
          .where((t) => _affectedStatuses.contains(t.status))
          .toList();
      
      final resyncedTasks = [...preservedTasks, ...affectedTasks];
      
      emit(state.copyWith(tasks: resyncedTasks));
    } catch (e) {
      // If resync fails, show error and restore previous state
      emit(state.copyWith(
        error: 'Failed to resync: ${e.toString()}',
        isReorderInFlight: false,
      ));
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
