import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/task_board_cubit.dart';
import '../cubit/search_cubit.dart';
import '../models/task.dart';
import '../widgets/task_column_new.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/search_bar_widget.dart';

class TaskBoardPage extends StatelessWidget {
  const TaskBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            
            // Filter tasks based on search
            final filteredGrouped = <TaskStatus, List<Task>>{};
            for (final entry in grouped.entries) {
              filteredGrouped[entry.key] = entry.value.where((task) {
                final searchText = '${task.title} ${task.description ?? ''}'
                    .toLowerCase();
                return searchCubit.matchesSearch(searchText);
              }).toList();
            }

            return Column(
              children: [
                SearchBarWidget(
                  onChanged: (query) => searchCubit.updateQuery(query),
                  onClear: () => searchCubit.clearSearch(),
                  onNewTask: () => _showTaskSheet(context),
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
                                        onAdd: () => _showTaskSheet(context, initialStatus: status),
                                        onMove: (taskId, toStatus) =>
                                            context.read<TaskBoardCubit>().moveTask(taskId, toStatus),
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
