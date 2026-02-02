import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../board/data/task_api_service.dart';
import '../../board/models/task.dart';
import '../data/field_api_service.dart';
import '../models/field.dart';
import '../models/assignee.dart';

class TasksListState extends Equatable {
  const TasksListState({
    required this.tasks,
    required this.fields,
    required this.taskFieldById,
    required this.taskAssigneesById,
    required this.taskFieldValuesByTaskId,
    this.viewMode = TaskViewMode.list,
    this.sortKey = TaskSortKey.manual,
    this.sortAscending = false,
    this.query = '',
    this.isLoading = false,
    this.error,
  });

  final List<Task> tasks;
  final List<Field> fields;
  // taskId -> fieldId
  final Map<String, String?> taskFieldById;
  // taskId -> { fieldId: value }
  final Map<String, Map<String, Object?>> taskFieldValuesByTaskId;
  // taskId -> [assignees]
  final Map<String, List<Assignee>> taskAssigneesById;
  final TaskViewMode viewMode;
  final TaskSortKey sortKey;
  final bool sortAscending;
  final String query;
  final bool isLoading;
  final String? error;

  /// Get filtered tasks based on search query
  List<Task> get filteredTasks => _applyQueryFilter(tasks);

  /// Get filtered + sorted tasks
  List<Task> get sortedTasks {
    final filtered = filteredTasks;
    if (sortKey == TaskSortKey.manual) return filtered;
    final sorted = List<Task>.from(filtered);
    sorted.sort((a, b) {
      int cmp;
      switch (sortKey) {
        case TaskSortKey.manual:
          cmp = a.order.compareTo(b.order);
          break;
        case TaskSortKey.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case TaskSortKey.status:
          cmp = a.status.label.toLowerCase().compareTo(
            b.status.label.toLowerCase(),
          );
          break;
        case TaskSortKey.dueDate:
          final ad = a.dueDate;
          final bd = b.dueDate;
          if (ad == null && bd == null) {
            cmp = 0;
          } else if (ad == null)
            cmp = 1; // nulls last when ascending
          else if (bd == null)
            cmp = -1;
          else
            cmp = ad.compareTo(bd);
          break;
        case TaskSortKey.createdAt:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<Task> _applyQueryFilter(List<Task> input) {
    if (query.trim().isEmpty) return input;
    final q = query.trim().toLowerCase();
    return input.where((t) {
      final title = t.title.toLowerCase();
      final desc = (t.description ?? '').toLowerCase();
      final status = t.status.label.toLowerCase();
      return title.contains(q) || desc.contains(q) || status.contains(q);
    }).toList();
  }

  /// Get field by ID
  Field? getFieldById(String fieldId) {
    try {
      return fields.firstWhere((f) => f.id == fieldId);
    } catch (e) {
      return null;
    }
  }

  TasksListState copyWith({
    List<Task>? tasks,
    List<Field>? fields,
    Map<String, String?>? taskFieldById,
    Map<String, List<Assignee>>? taskAssigneesById,
    Map<String, Map<String, Object?>>? taskFieldValuesByTaskId,
    TaskViewMode? viewMode,
    TaskSortKey? sortKey,
    bool? sortAscending,
    String? query,
    bool? isLoading,
    String? error,
  }) => TasksListState(
    tasks: tasks ?? this.tasks,
    fields: fields ?? this.fields,
    taskFieldById: taskFieldById ?? this.taskFieldById,
    taskFieldValuesByTaskId:
        taskFieldValuesByTaskId ?? this.taskFieldValuesByTaskId,
    taskAssigneesById: taskAssigneesById ?? this.taskAssigneesById,
    viewMode: viewMode ?? this.viewMode,
    sortKey: sortKey ?? this.sortKey,
    sortAscending: sortAscending ?? this.sortAscending,
    query: query ?? this.query,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  @override
  List<Object?> get props => [
    tasks,
    fields,
    taskFieldById,
    taskAssigneesById,
    taskFieldValuesByTaskId,
    viewMode,
    sortKey,
    sortAscending,
    query,
    isLoading,
    error,
  ];
}

enum TaskViewMode { list, calendar, roadmap }

enum TaskSortKey { manual, title, status, dueDate, createdAt }

class TasksListCubit extends Cubit<TasksListState> {
  TasksListCubit({
    required TaskApiService taskApiService,
    required FieldApiService fieldApiService,
  })  : _taskApiService = taskApiService,
        _fieldApiService = fieldApiService,
        super(
          const TasksListState(
            tasks: [],
            fields: [],
            taskFieldById: {},
            taskAssigneesById: {},
            taskFieldValuesByTaskId: {},
          ),
        ) {
    _scheduleDailySync();
  }

  final TaskApiService _taskApiService;
  final FieldApiService _fieldApiService;
  Timer? _syncTimer;

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }

  void _scheduleDailySync() {
    // Calculate time until next UTC 12:00
    final now = DateTime.now().toUtc();
    var nextSync = DateTime.utc(now.year, now.month, now.day, 12, 0);
    
    // If we've already passed 12:00 UTC today, schedule for tomorrow
    if (now.isAfter(nextSync)) {
      nextSync = nextSync.add(const Duration(days: 1));
    }
    
    final initialDelay = nextSync.difference(now);
    
    // Schedule first sync
    Future.delayed(initialDelay, () async {
      await _performScheduledSync();
      
      // Then schedule daily syncs
      _syncTimer = Timer.periodic(const Duration(days: 1), (_) async {
        await _performScheduledSync();
      });
    });
  }

  Future<void> _performScheduledSync() async {
    try {
      await _fieldApiService.syncFields(state.fields);
    } catch (e) {
      // Log but don't interrupt user experience
      debugPrint('Scheduled field sync failed: $e');
    }
  }

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Load both tasks and fields from API
      final tasksResult = await _taskApiService.fetchAllTasks();
      final fieldsResult = await _fieldApiService.fetchFields();
      
      final orderedTasks = List<Task>.from(tasksResult)
        ..sort((a, b) => a.order.compareTo(b.order));
      
      // Build field values map from fetched tasks
      // Ensure every task has an entry for every field
      final values = <String, Map<String, Object?>>{};
      for (final t in orderedTasks) {
        values[t.id] = {};
        
        // Copy any existing field values from task
        if (t.fieldValues != null && t.fieldValues!.isNotEmpty) {
          values[t.id]!.addAll(t.fieldValues!);
        }
        
        // Ensure every field has an entry (even if null) for consistency
        for (final field in fieldsResult) {
          values[t.id]!.putIfAbsent(field.id, () => null);
        }
      }
      
      emit(
        state.copyWith(
          tasks: orderedTasks,
          fields: fieldsResult,
          taskFieldValuesByTaskId: values,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadTasks() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final tasks = await _taskApiService.fetchAllTasks();
      final orderedTasks = List<Task>.from(tasks)
        ..sort((a, b) => a.order.compareTo(b.order));
      emit(state.copyWith(tasks: orderedTasks, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Fields are managed client-side for now
  void loadFields() {}

  void setQuery(String value) {
    emit(state.copyWith(query: value));
  }

  void setViewMode(TaskViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  void setSort(TaskSortKey key) {
    final isSameKey = key == state.sortKey;
    final nextAscending = isSameKey ? !state.sortAscending : true;
    emit(state.copyWith(sortKey: key, sortAscending: nextAscending));
  }

  Future<void> createField({
    required String name,
    required FieldType type,
    List<String> options = const [],
    required String color,
  }) async {
    final newField = Field(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      options: type == FieldType.singleSelect ? options : const [],
      color: _hexToColor(color),
      createdAt: DateTime.now(),
    );
    
    // Optimistically update UI
    final updatedFields = [...state.fields, newField];
    final values = Map<String, Map<String, Object?>>.from(
      state.taskFieldValuesByTaskId,
    );
    for (final t in state.tasks) {
      values[t.id] = Map<String, Object?>.from(values[t.id] ?? {});
      values[t.id]![newField.id] = null;
    }
    emit(
      state.copyWith(fields: updatedFields, taskFieldValuesByTaskId: values),
    );
    
    // Persist to backend immediately
    try {
      final createdField = await _fieldApiService.createField(newField);
      // Update with server-generated data if needed
      final serverFields = state.fields
          .map((f) => f.id == newField.id ? createdField : f)
          .toList();
      emit(state.copyWith(fields: serverFields));
    } catch (e) {
      // Roll back on failure
      final rolledBackFields = state.fields
          .where((f) => f.id != newField.id)
          .toList();
      emit(state.copyWith(fields: rolledBackFields, error: e.toString()));
    }
  }

  Future<void> updateField({
    required String fieldId,
    required String name,
    required String color,
  }) async {
    // Optimistically update UI
    final oldFields = state.fields;
    final updatedFields = state.fields
        .map(
          (f) => f.id == fieldId
              ? f.copyWith(
                  name: name,
                  color: _hexToColor(color),
                  updatedAt: DateTime.now(),
                )
              : f,
        )
        .toList();
    emit(state.copyWith(fields: updatedFields));
    
    // Persist to backend immediately
    try {
      final field = updatedFields.firstWhere((f) => f.id == fieldId);
      await _fieldApiService.updateField(fieldId, field);
    } catch (e) {
      // Roll back on failure
      emit(state.copyWith(fields: oldFields, error: e.toString()));
    }
  }

  Future<void> deleteField(String fieldId) async {
    // Store old state for rollback
    final oldFields = state.fields;
    final oldTaskFieldById = state.taskFieldById;
    final oldTaskFieldValuesByTaskId = state.taskFieldValuesByTaskId;
    
    // Optimistically update UI
    final updatedFields = state.fields.where((f) => f.id != fieldId).toList();
    final updatedTaskFieldById = Map<String, String?>.from(state.taskFieldById)
      ..removeWhere((_, value) => value == fieldId);
    final values = Map<String, Map<String, Object?>>.from(
      state.taskFieldValuesByTaskId,
    );
    for (final entry in values.entries) {
      entry.value.remove(fieldId);
    }
    
    emit(
      state.copyWith(
        fields: updatedFields,
        taskFieldById: updatedTaskFieldById,
        taskFieldValuesByTaskId: values,
      ),
    );
    
    // Persist to backend immediately (soft delete)
    try {
      await _fieldApiService.deleteField(fieldId);
    } catch (e) {
      // Roll back on failure
      emit(
        state.copyWith(
          fields: oldFields,
          taskFieldById: oldTaskFieldById,
          taskFieldValuesByTaskId: oldTaskFieldValuesByTaskId,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String? fieldId,
  }) async {
    try {
      final task = await _taskApiService.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
      );
      final updatedTasks = [...state.tasks, task]
        ..sort((a, b) => a.order.compareTo(b.order));
      final updatedTaskFieldById = Map<String, String?>.from(
        state.taskFieldById,
      );
      if (fieldId != null) {
        updatedTaskFieldById[task.id] = fieldId;
      }
      emit(
        state.copyWith(
          tasks: updatedTasks,
          taskFieldById: updatedTaskFieldById,
        ),
      );
      // Initialize field values for the new task
      final values = Map<String, Map<String, Object?>>.from(
        state.taskFieldValuesByTaskId,
      );
      values[task.id] = {for (final f in state.fields) f.id: null};
      emit(
        state.copyWith(
          tasks: updatedTasks,
          taskFieldById: updatedTaskFieldById,
          taskFieldValuesByTaskId: values,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final updatedTask = await _taskApiService.updateTask(
        taskId: task.id,
        title: task.title,
        description: task.description,
        status: task.status.value,
        dueDate: task.dueDate,
        fieldValues: state.taskFieldValuesByTaskId[task.id],
      );
      final updatedTasks = state.tasks
          .map((t) => t.id == task.id ? updatedTask : t)
          .toList();
      emit(state.copyWith(tasks: updatedTasks));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void setTaskField({required String taskId, String? fieldId}) {
    final updated = Map<String, String?>.from(state.taskFieldById);
    updated[taskId] = fieldId;
    emit(state.copyWith(taskFieldById: updated));
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskApiService.deleteTask(taskId);
      final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
      final values = Map<String, Map<String, Object?>>.from(
        state.taskFieldValuesByTaskId,
      );
      values.remove(taskId);
      emit(
        state.copyWith(tasks: updatedTasks, taskFieldValuesByTaskId: values),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateTaskFieldValue({
    required String taskId,
    required String fieldId,
    required Object? value,
  }) async {
    final values = Map<String, Map<String, Object?>>.from(
      state.taskFieldValuesByTaskId,
    );
    values[taskId] = Map<String, Object?>.from(values[taskId] ?? {});
    values[taskId]![fieldId] = value;
    emit(state.copyWith(taskFieldValuesByTaskId: values));
    // Persist via singular update API
    try {
      await _taskApiService.updateTask(
        taskId: taskId,
        fieldValues: {fieldId: value},
      );
    } catch (e) {
      // Keep optimistic UI; optionally roll back on failure
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    var targetIndex = newIndex;
    if (newIndex > oldIndex) targetIndex -= 1;

    final orderedIds = List<String>.from(
      state.sortedTasks.map((task) => task.id),
    );
    final movedId = orderedIds.removeAt(oldIndex);
    orderedIds.insert(targetIndex, movedId);

    final visibleTasks = orderedIds
        .map((id) => state.tasks.firstWhere((task) => task.id == id))
        .toList();
    final remainingTasks = state.tasks
        .where((task) => !orderedIds.contains(task.id))
        .toList();

    final combined = [...visibleTasks, ...remainingTasks];
    final reindexed = List<Task>.generate(
      combined.length,
      (i) => combined[i].copyWith(order: i),
    );

    emit(
      state.copyWith(
        tasks: reindexed,
        sortKey: TaskSortKey.manual,
        sortAscending: true,
      ),
    );

    try {
      await _taskApiService.reorderTasks(reindexed.map((t) => t.id).toList());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void assignUser({required String taskId, required Assignee assignee}) {
    final updated = Map<String, List<Assignee>>.from(state.taskAssigneesById);
    final current = List<Assignee>.from(updated[taskId] ?? const []);
    current.add(assignee);
    updated[taskId] = current;
    emit(state.copyWith(taskAssigneesById: updated));
  }

  void unassignUser({required String taskId, required String assigneeId}) {
    final updated = Map<String, List<Assignee>>.from(state.taskAssigneesById);
    final current = List<Assignee>.from(updated[taskId] ?? const []);
    updated[taskId] = current.where((a) => a.id != assigneeId).toList();
    emit(state.copyWith(taskAssigneesById: updated));
  }
}

// helper
Color _hexToColor(String hexColor) {
  final hexString = hexColor.replaceFirst('#', '');
  return Color(int.parse('FF$hexString', radix: 16));
}
