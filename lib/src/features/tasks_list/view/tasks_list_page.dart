import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../board/models/task.dart';
import '../../board/widgets/task_editor_sheet.dart';
import '../../preferences/cubit/preferences_cubit.dart';
import '../cubit/tasks_list_cubit.dart';
import '../widgets/calendar_view.dart';
import '../widgets/field_widgets.dart';
import '../widgets/roadmap_view.dart';
import '../widgets/task_list_table.dart';
import '../widgets/view_toggle_buttons.dart';
import '../../../widgets/animated_focus_text_field.dart';
import '../../agent/view/agent_panel.dart';

// Design Language: Multi-view list/calendar/roadmap with fluid transitions
// See DESIGN_LANGUAGE.md for animation timings and layout rules
class TasksListPage extends StatefulWidget {
  const TasksListPage({super.key});

  @override
  State<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends State<TasksListPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<TasksListCubit>();
    cubit.loadInitialData();
    cubit.syncFromPreferences(context.read<PreferencesCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksListCubit, TasksListState>(
      builder: (context, state) {
        if (state.isLoading && state.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
                    context.read<TasksListCubit>().loadInitialData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.viewMode == TaskViewMode.roadmap) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ViewToggleButtons(
                    currentViewMode: state.viewMode,
                    onModeSelected: (mode) {
                      context.read<TasksListCubit>().setViewMode(mode);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AnimatedFocusTextField(
                  prefixIcon: const Icon(Icons.auto_awesome, size: 18),
                  hintText: 'Search tasks or ask anything...',
                  onChanged: (value) {
                    context.read<TasksListCubit>().setQuery(value);
                  },
                  onSubmitted: (value) => _handleSearchSubmit(context, value),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: RoadmapView(
                    key: const ValueKey('roadmap_view'),
                    tasks: state.sortedTasks,
                    onAddTaskAtDate: (date) {
                      _showCreateTaskDialog(context, initialDueDate: date);
                    },
                    onTaskTap: (task) => _showTaskDetails(context, task),
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await context.read<TasksListCubit>().loadInitialData();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ViewToggleButtons(
                    currentViewMode: state.viewMode,
                    onModeSelected: (mode) {
                      context.read<TasksListCubit>().setViewMode(mode);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Design Language: Focus-animated filter input (200ms)
                AnimatedFocusTextField(
                  prefixIcon: const Icon(Icons.auto_awesome, size: 18),
                  hintText: 'Search tasks or ask anything...',
                  onChanged: (value) {
                    context.read<TasksListCubit>().setQuery(value);
                  },
                  onSubmitted: (value) => _handleSearchSubmit(context, value),
                ),
                const SizedBox(height: 24),
                // Task Count
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Tasks (${state.sortedTasks.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                // Design Language: View transition animation (200ms)
                Builder(
                  builder: (context) {
                    final Widget viewBody;
                    if (state.viewMode == TaskViewMode.list) {
                      viewBody = TaskListTable(
                        key: const ValueKey('list_view'),
                        tasks: state.sortedTasks,
                        fields: state.fields,
                        taskFieldById: state.taskFieldById,
                        taskFieldValuesByTaskId: state.taskFieldValuesByTaskId,
                        sortKey: state.sortKey,
                        sortAscending: state.sortAscending,
                        onTaskUpdate: (task) {
                          context.read<TasksListCubit>().updateTask(task);
                        },
                        onTaskDelete: (taskId) {
                          context.read<TasksListCubit>().deleteTask(taskId);
                        },
                        onAddField: () {
                          showDialog(
                            context: context,
                            builder: (context) => const CreateFieldDialog(),
                          );
                        },
                        onSortChanged: (key) {
                          context.read<TasksListCubit>().setSort(key);
                        },
                        onAddTask: (title) {
                          context.read<TasksListCubit>().createTask(
                                title: title,
                                description: null,
                                dueDate: null,
                                fieldValues: const {},
                              );
                        },
                        onFieldValueChange: (taskId, fieldId, value) {
                          context.read<TasksListCubit>().updateTaskFieldValue(
                                taskId: taskId,
                                fieldId: fieldId,
                                value: value,
                              );
                        },
                        onReorder: (oldIndex, newIndex) {
                          context
                              .read<TasksListCubit>()
                              .reorderTasks(oldIndex, newIndex);
                        },
                        onFieldReorder: (oldIndex, newIndex) {
                          context
                              .read<TasksListCubit>()
                              .reorderFields(oldIndex, newIndex);
                        },
                      );
                    } else if (state.viewMode == TaskViewMode.calendar) {
                      viewBody = CalendarView(
                        key: const ValueKey('calendar_view'),
                        tasks: state.sortedTasks,
                        onTaskTap: (task) => _showTaskDetails(context, task),
                        onAddTaskAtDate: (date) {
                          _showCreateTaskDialog(context, initialDueDate: date);
                        },
                      );
                    } else {
                      viewBody = const SizedBox.shrink();
                    }

                    return Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final fade = FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(animation);
                          return SlideTransition(position: slide, child: fade);
                        },
                        child: viewBody,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateTaskDialog(
    BuildContext context, {
    DateTime? initialDueDate,
  }) {
    final cubit = context.read<TasksListCubit>();
    TaskEditorSheet.show(
      context,
      fields: cubit.state.fields,
      initialDueDate: initialDueDate,
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    final cubit = context.read<TasksListCubit>();
    TaskEditorSheet.show(
      context,
      task: task,
      fields: cubit.state.fields,
    );
  }

  /// Detect if input looks like an agent request vs. a task filter.
  bool _isAgentQuery(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.length < 5) return false;

    const agentVerbs = [
      'create', 'find', 'summarize', 'analyze', 'show me', 'what',
      'how many', 'list all', 'report', 'overdue', 'search for',
      'help me', 'generate', 'break down', 'draft', 'suggest',
      'who', 'where', 'when', 'why', 'update all', 'move all',
    ];

    return agentVerbs.any((v) => lower.contains(v));
  }

  void _handleSearchSubmit(BuildContext context, String value) {
    if (_isAgentQuery(value)) {
      AgentPanel.show(context, initialQuery: value);
    }
  }
}
