import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/tasks_list_cubit.dart';
import '../models/field.dart';
import '../widgets/field_widgets.dart';
import '../widgets/task_list_table.dart';

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
      appBar: AppBar(title: const Text('Tasks List'), elevation: 0),
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
                    // Filter bar
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Filter by keyword or by field',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                    // Tasks Table
                    TaskListTable(
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
                          fieldId: null,
                        );
                      },
                      onFieldValueChange: (taskId, fieldId, value) {
                        context.read<TasksListCubit>().updateTaskFieldValue(
                          taskId: taskId,
                          fieldId: fieldId,
                          value: value,
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

  void _showCreateTaskDialog(BuildContext context) {
    final cubit = context.read<TasksListCubit>();
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        fields: cubit.state.fields,
        onSave: (title, description, dueDate, fieldId) {
          cubit.createTask(
            title: title,
            description: description,
            dueDate: dueDate,
            fieldId: fieldId,
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({
    super.key,
    required this.fields,
    required this.onSave,
  });

  final List<Field> fields;
  final Function(
    String title,
    String? description,
    DateTime? dueDate,
    String? fieldId,
  )
  onSave;

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String? _selectedFieldId;
  late DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedFieldId = null;
    _selectedDueDate = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (widget.fields.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedFieldId,
                decoration: InputDecoration(
                  labelText: 'Field',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Field')),
                  ...widget.fields.map((field) {
                    return DropdownMenuItem(
                      value: field.id,
                      child: Text(field.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFieldId = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(
                _selectedDueDate != null
                    ? '${_selectedDueDate!.year}-${_selectedDueDate!.month}-${_selectedDueDate!.day}'
                    : 'Not set',
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
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _selectedDueDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDueDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
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
              _selectedFieldId,
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
