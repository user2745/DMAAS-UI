import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks_list/models/field.dart';
import '../cubit/task_board_cubit.dart';
import '../cubit/search_cubit.dart';
import '../models/task.dart';
import '../widgets/task_column_new.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/search_bar_widget.dart';

class TaskBoardPage extends StatefulWidget {
  const TaskBoardPage({super.key});

  @override
  State<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends State<TaskBoardPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load fields when page is first created
    context.read<TaskBoardCubit>().loadFields();
  }

  @override
  void didUpdateWidget(TaskBoardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload fields when widget updates (e.g., after returning from another tab)
    context.read<TaskBoardCubit>().loadFields();
  }

  /// Extract unique field names and values from all tasks for filter options
  Map<String, (String, List<String>)> _getAvailableFields(
    List<Task> tasks,
    List<Field> fields,
  ) {
    final fieldMap = <String, String>{};
    
    // Build a map of fieldId -> fieldName from loaded fields
    for (final field in fields) {
      fieldMap[field.id] = field.name;
    }

    final resultMap = <String, (String, Set<String>)>{};

    for (final task in tasks) {
      if (task.fieldValues != null) {
        for (final entry in task.fieldValues!.entries) {
          final fieldId = entry.key;
          final value = entry.value;

          if (!resultMap.containsKey(fieldId)) {
            // Use loaded field name, or fieldId as fallback
            final fieldName = fieldMap[fieldId] ?? fieldId;
            resultMap[fieldId] = (fieldName, <String>{});
          }

          // Add value to the set of unique values for this field
          if (value != null) {
            final valueStr = value is List
                ? value.map((v) => v.toString()).join(', ')
                : value.toString();
            resultMap[fieldId]!.$2.add(valueStr);
          }
        }
      }
    }

    // Convert to final format: (fieldId, fieldName, sortedOptions)
    return {
      for (final entry in resultMap.entries)
        entry.key: (entry.value.$1, entry.value.$2.toList()..sort()),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocBuilder<TaskBoardCubit, TaskBoardState>(
      builder: (context, state) {
        if (state.isLoading && state.tasks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.error != null && state.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TaskBoardCubit>().loadTasks();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return BlocBuilder<SearchCubit, SearchState>(
          builder: (context, searchState) {
            final searchCubit = context.read<SearchCubit>();
            final grouped = state.groupedByStatus;
            
            // Get available fields from current tasks and loaded field metadata
            final availableFields = _getAvailableFields(state.tasks, state.fields);
            final filterOptions = availableFields.entries
                .map((e) => (e.key, e.value.$1, e.value.$2))
                .toList();
            
            // Filter tasks based on search and field filters
            final filteredGrouped = <TaskStatus, List<Task>>{};
            for (final entry in grouped.entries) {
              filteredGrouped[entry.key] = entry.value.where((task) {
                final searchText = '${task.title} ${task.description ?? ''}'
                    .toLowerCase();
                return searchCubit.matches(searchText, task.fieldValues);
              }).toList();
            }

            return Column(
              children: [
                SearchBarWidget(
                  onChanged: (query) => searchCubit.updateQuery(query),
                  onClear: () => searchCubit.clearSearch(),
                  onNewTask: () => _showTaskSheet(context),
                  onFieldFilterChanged: (filter) {
                    if (filter != null) {
                      searchCubit.addFieldFilter(filter);
                    }
                  },
                  onClearFilters: () => searchCubit.clearFieldFilters(),
                  availableFilters: filterOptions,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double columnWidth = math.max(
                        constraints.maxWidth / TaskStatus.values.length,
                        320,
                      );

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: TaskStatus.values
                                  .map(
                                    (status) => SizedBox(
                                      width: columnWidth,
                                      child: TaskColumn(
                                        status: status,
                                        tasks: filteredGrouped[status] ?? const [],
                                        fields: state.fields,
                                        isReorderInFlight: state.isReorderInFlight,
                                        onAdd: () => _showTaskSheet(context, initialStatus: status),
                                        onMove: (taskId, toStatus) =>
                                            context.read<TaskBoardCubit>().moveTask(taskId, toStatus),
                                        onReorder: (taskId, toStatus, toIndex) =>
                                            context.read<TaskBoardCubit>().reorderTask(
                                              taskId: taskId,
                                              toStatus: toStatus,
                                              toIndex: toIndex,
                                            ),
                                        onRemove: (taskId) =>
                                            context.read<TaskBoardCubit>().removeTask(taskId),
                                        onEdit: (task) => _showTaskSheet(context, task: task),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskSheet(
    BuildContext context, {
    Task? task,
    TaskStatus? initialStatus,
  }) {
    TaskEditorSheet.show(context, task: task, initialStatus: initialStatus);
  }
}
