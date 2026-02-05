import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../board/models/task.dart';
import '../../board/widgets/task_detail_modal.dart';
import '../cubit/tasks_list_cubit.dart';
import '../models/field.dart';
import '../widgets/calendar_view.dart';
import '../widgets/field_widgets.dart';
import '../widgets/roadmap_view.dart';
import '../widgets/task_list_table.dart';
import '../widgets/view_toggle_buttons.dart';
import '../../../widgets/animated_focus_text_field.dart';

class TasksListPage extends StatefulWidget {
  const TasksListPage({super.key});

  @override
  State<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends State<TasksListPage> {
  @override
  void initState() {
    super.initState();
    context.read<TasksListCubit>().loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Expanded(child: Text('Activities List')),
            ViewToggleButtons(
              currentViewMode: context.watch<TasksListCubit>().state.viewMode,
              onModeSelected: (mode) {
                context.read<TasksListCubit>().setViewMode(mode);
              },
            ),
          ],
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateTaskDialog(context);
        },
        tooltip: 'Create Task',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TasksListCubit, TasksListState>(
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

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<TasksListCubit>().loadInitialData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Design Language: Focus-animated filter input (200ms)
                    AnimatedFocusTextField(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Filter by keyword or by field',
                      onChanged: (value) {
                        context.read<TasksListCubit>().setQuery(value);
                      },
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
                          );
                        } else if (state.viewMode == TaskViewMode.calendar) {
                          viewBody = CalendarView(
                            key: const ValueKey('calendar_view'),
                            tasks: state.sortedTasks,
                            onTaskTap: (task) => _showTaskDetails(context, task),
                          );
                        } else {
                          viewBody = RoadmapView(
                            key: const ValueKey('roadmap_view'),
                            tasks: state.sortedTasks,
                            onAddTaskAtDate: (date) {
                              _showCreateTaskDialog(
                                context,
                                initialDueDate: date,
                              );
                            },
                            onTaskTap: (task) => _showTaskDetails(context, task),
                          );
                        }

                        return AnimatedSwitcher(
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateTaskDialog(
    BuildContext context, {
    DateTime? initialDueDate,
  }) {
    final cubit = context.read<TasksListCubit>();
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        fields: cubit.state.fields,
        initialDueDate: initialDueDate,
        onSave: (title, description, dueDate, fieldValues) {
          cubit.createTask(
            title: title,
            description: description,
            dueDate: dueDate,
            fieldValues: fieldValues,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    final cubit = context.read<TasksListCubit>();
    TaskDetailModal.show(
      context,
      task: task,
      onAddComment: (text) async {
        await cubit.addComment(taskId: task.id, text: text);
        // Refresh the dialog with updated task
        if (context.mounted) {
          Navigator.pop(context);
          _showTaskDetails(context, cubit.state.tasks.firstWhere(
            (t) => t.id == task.id,
            orElse: () => task,
          ));
        }
      },
      onDeleteComment: (commentId) async {
        await cubit.deleteComment(taskId: task.id, commentId: commentId);
        // Refresh the dialog with updated task
        if (context.mounted) {
          Navigator.pop(context);
          _showTaskDetails(context, cubit.state.tasks.firstWhere(
            (t) => t.id == task.id,
            orElse: () => task,
          ));
        }
      },
    );
  }
}

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({
    super.key,
    required this.fields,
    this.initialDueDate,
    required this.onSave,
  });

  final List<Field> fields;
  final DateTime? initialDueDate;
  final Function(
    String title,
    String? description,
    DateTime? dueDate,
    Map<String, Object?> fieldValues,
  )
  onSave;

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime? _selectedDueDate;
  late Map<String, TextEditingController> _textControllers;
  late Map<String, String?> _singleSelectValues;
  late Map<String, DateTime?> _dateValues;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDueDate = widget.initialDueDate;
    _textControllers = {
      for (final field in widget.fields)
        if (field.type == FieldType.text) field.id: TextEditingController(),
    };
    _singleSelectValues = {
      for (final field in widget.fields)
        if (field.type == FieldType.singleSelect) field.id: null,
    };
    _dateValues = {
      for (final field in widget.fields)
        if (field.type == FieldType.date) field.id: null,
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> _collectFieldValues() {
    final values = <String, Object?>{};
    for (final entry in _textControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        values[entry.key] = text;
      }
    }
    for (final entry in _singleSelectValues.entries) {
      if (entry.value != null && entry.value!.trim().isNotEmpty) {
        values[entry.key] = entry.value!;
      }
    }
    for (final entry in _dateValues.entries) {
      if (entry.value != null) {
        values[entry.key] = entry.value!;
      }
    }
    return values;
  }

  Widget _buildFieldInput(BuildContext context, Field field) {
    final theme = Theme.of(context);
    
    switch (field.type) {
      case FieldType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: field.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  field.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: field.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: field.color.withAlpha(80), width: 0.8),
                  ),
                  child: Text(
                    'Text',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: field.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedFocusTextField(
              controller: _textControllers[field.id]!,
              labelText: '',
              hintText: 'Add ${field.name.toLowerCase()}...',
            ),
          ],
        );
      case FieldType.singleSelect:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: field.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  field.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: field.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: field.color.withAlpha(80), width: 0.8),
                  ),
                  child: Text(
                    'Select',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: field.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _singleSelectValues[field.id],
              decoration: InputDecoration(
                labelText: '',
                hintText: 'Select ${field.name.toLowerCase()}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...field.options.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _singleSelectValues[field.id] = value;
                });
              },
            ),
          ],
        );
      case FieldType.date:
        final selectedDate = _dateValues[field.id];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: field.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  field.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: field.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: field.color.withAlpha(80), width: 0.8),
                  ),
                  child: Text(
                    'Date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: field.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                dense: true,
                title: Text(
                  selectedDate != null
                      ? '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'
                      : 'Not set',
                  style: theme.textTheme.labelMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _dateValues[field.id] = null;
                          });
                        },
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final firstDate = now.subtract(
                          const Duration(days: 365 * 5),
                        );
                        final lastDate = now.add(const Duration(days: 365 * 5));
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? now,
                          firstDate: firstDate,
                          lastDate: lastDate,
                        );
                        if (date != null) {
                          setState(() {
                            _dateValues[field.id] = date;
                          });
                        }
                      },
                      iconSize: 18,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'New Task',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Title',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedFocusTextField(
                          controller: _titleController,
                          labelText: '',
                          hintText: 'Add a task title...',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedFocusTextField(
                          controller: _descriptionController,
                          labelText: '',
                          hintText: 'Add details... (optional)',
                          minLines: 3,
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Due Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            dense: true,
                            title: Text(
                              _selectedDueDate != null
                                  ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                                  : 'Not set',
                              style: theme.textTheme.labelMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedDueDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDueDate = null;
                                      });
                                    },
                                    iconSize: 18,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDueDate ?? now.add(const Duration(days: 7)),
                                      firstDate: now.subtract(const Duration(days: 365 * 5)),
                                      lastDate: now.add(const Duration(days: 365 * 5)),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _selectedDueDate = date;
                                      });
                                    }
                                  },
                                  iconSize: 18,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Fields section
                    if (widget.fields.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            'Custom Fields',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optional',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.fields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildFieldInput(context, field),
                        );
                      }),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            
            // Footer with actions
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }
                      widget.onSave(
                        title,
                        _descriptionController.text.trim().isEmpty
                            ? null
                            : _descriptionController.text.trim(),
                        _selectedDueDate,
                        _collectFieldValues(),
                      );
                    },
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
