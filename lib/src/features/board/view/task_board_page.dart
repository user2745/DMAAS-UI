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

// Design Language: Kanban board with smooth column animations and responsive layout
// See DESIGN_LANGUAGE.md for spacing, motion, and shadow specifications
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
                      final cubit = context.read<TaskBoardCubit>();
                      final collapsed = state.collapsedStatuses;

                      // Responsive: auto-collapse columns when viewport < 700
                      final isNarrow = constraints.maxWidth < 700;
                      Set<TaskStatus> effectiveCollapsed;
                      if (isNarrow) {
                        // On narrow viewports, collapse all but the first expanded
                        final firstExpanded = TaskStatus.values.firstWhere(
                          (s) => !collapsed.contains(s),
                          orElse: () => TaskStatus.values.first,
                        );
                        effectiveCollapsed = TaskStatus.values
                            .where((s) => s != firstExpanded)
                            .toSet();
                      } else {
                        effectiveCollapsed = collapsed;
                      }

                      final expandedStatuses = TaskStatus.values
                          .where((s) => !effectiveCollapsed.contains(s))
                          .toList();
                      final collapsedStatuses = TaskStatus.values
                          .where((s) => effectiveCollapsed.contains(s))
                          .toList();

                      const collapsedTabWidth = 48.0;
                      final collapsedTotalWidth = collapsedTabWidth + 8;
                      final availableWidth =
                          constraints.maxWidth - 32 - collapsedTotalWidth; // 32 = padding
                      final double columnWidth = expandedStatuses.isNotEmpty
                          ? math.max(availableWidth / expandedStatuses.length, 280)
                          : 280;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Expanded columns
                                ...expandedStatuses.map(
                                  (status) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: columnWidth,
                                    child: TaskColumn(
                                      status: status,
                                      tasks: filteredGrouped[status] ?? const [],
                                      fields: state.fields,
                                      isReorderInFlight: state.isReorderInFlight,
                                      onAdd: () => _showTaskSheet(
                                        context,
                                        initialStatus: status,
                                      ),
                                      onMove: (taskId, toStatus) =>
                                          cubit.moveTask(taskId, toStatus),
                                      onReorder: (taskId, toStatus, toIndex) =>
                                          cubit.reorderTask(
                                            taskId: taskId,
                                            toStatus: toStatus,
                                            toIndex: toIndex,
                                          ),
                                      onRemove: (taskId) =>
                                          cubit.removeTask(taskId),
                                      onEdit: (task) =>
                                          _showTaskSheet(context, task: task),
                                      onCollapse: () =>
                                          cubit.toggleColumnCollapse(status),
                                    ),
                                  ),
                                ),
                                // Collapsed tab strip + add column button
                                SizedBox(
                                  width: collapsedTabWidth,
                                  child: Column(
                                    children: [
                                      ...collapsedStatuses.map(
                                        (status) => _CollapsedColumnTab(
                                          status: status,
                                          taskCount:
                                              (filteredGrouped[status] ?? []).length,
                                          onExpand: () =>
                                              cubit.toggleColumnCollapse(status),
                                          onTaskDropped: (task) =>
                                              _moveToCollapsedColumn(
                                            context,
                                            task,
                                            status,
                                          ),
                                          isReorderInFlight:
                                              state.isReorderInFlight,
                                        ),
                                      ),
                                      // Add column button
                                      _AddColumnButton(
                                        onTap: () => _showCreateColumnDialog(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    final state = context.read<TaskBoardCubit>().state;
    TaskEditorSheet.show(
      context,
      task: task,
      initialStatus: initialStatus,
      fields: state.fields,
    );
  }

  /// Optimistically move a task to a collapsed column and show a snackbar
  void _moveToCollapsedColumn(
    BuildContext context,
    Task task,
    TaskStatus toStatus,
  ) {
    final cubit = context.read<TaskBoardCubit>();
    cubit.moveTask(task.id, toStatus).then((_) {
      if (!context.mounted) return;
      final currentState = cubit.state;
      if (currentState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move "${task.title}"'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Show optimistic snackbar immediately
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: toStatus.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Moved "${task.title}" to ${toStatus.label}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showCreateColumnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Column'),
        content: const Text(
          'Custom columns are coming soon! '
          'Currently the board supports To Do, In Progress, and Done.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// A collapsed column tab shown as a vertical rotated strip on the right side.
/// Acts as a DragTarget for silently moving tasks into the collapsed column.
class _CollapsedColumnTab extends StatefulWidget {
  const _CollapsedColumnTab({
    required this.status,
    required this.taskCount,
    required this.onExpand,
    required this.onTaskDropped,
    this.isReorderInFlight = false,
  });

  final TaskStatus status;
  final int taskCount;
  final VoidCallback onExpand;
  final void Function(Task task) onTaskDropped;
  final bool isReorderInFlight;

  @override
  State<_CollapsedColumnTab> createState() => _CollapsedColumnTabState();
}

class _CollapsedColumnTabState extends State<_CollapsedColumnTab> {
  bool _isDragHover = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        // Accept tasks from other columns, not from this status
        return details.data.status != widget.status &&
            !widget.isReorderInFlight;
      },
      onAcceptWithDetails: (details) {
        widget.onTaskDropped(details.data);
        setState(() => _isDragHover = false);
      },
      onMove: (_) {
        if (!_isDragHover) setState(() => _isDragHover = true);
      },
      onLeave: (_) {
        if (_isDragHover) setState(() => _isDragHover = false);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: widget.onExpand,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              color: _isDragHover
                  ? widget.status.color.withAlpha(40)
                  : Theme.of(context).cardColor.withAlpha(230),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isDragHover
                    ? widget.status.color.withAlpha(180)
                    : widget.status.color.withAlpha(60),
                width: _isDragHover ? 2.5 : 1.5,
              ),
              boxShadow: _isDragHover
                  ? [
                      BoxShadow(
                        color: widget.status.color.withAlpha(50),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.status.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.status.color.withAlpha(80),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Task count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.status.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.taskCount}',
                    style: TextStyle(
                      color: widget.status.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Rotated label
                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    widget.status.label,
                    style: TextStyle(
                      color: widget.status.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Expand icon
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: widget.status.color.withAlpha(150),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A small "+" button shown at the bottom of the collapsed column strip.
class _AddColumnButton extends StatelessWidget {
  const _AddColumnButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(180),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
        ),
      ),
    );
  }
}
