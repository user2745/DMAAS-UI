import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../cubit/task_board_cubit.dart';
import '../models/task.dart';

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task, this.initialStatus});

  final Task? task;
  final TaskStatus? initialStatus;

  static Future<void> show(
    BuildContext context, {
    Task? task,
    TaskStatus? initialStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: TaskEditorSheet(task: task, initialStatus: initialStatus),
        );
      },
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assigneeController;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _assigneeController = TextEditingController(
      text: widget.task?.assignee ?? '',
    );
    _status = widget.task?.status ?? widget.initialStatus ?? TaskStatus.backlog;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isEditing ? 'Update task' : 'Create task',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _assigneeController,
              decoration: const InputDecoration(labelText: 'Owner (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: TaskStatus.values
                  .map(
                    (s) => DropdownMenuItem<TaskStatus>(
                      value: s,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submit(context),
                icon: Icon(isEditing ? Icons.save_outlined : Icons.add_task),
                label: Text(isEditing ? 'Save changes' : 'Create task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<TaskBoardCubit>();
    final trimmedDescription = _descriptionController.text.trim();
    final trimmedAssignee = _assigneeController.text.trim();

    if (widget.task == null) {
      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: trimmedDescription,
        status: _status,
        createdAt: DateTime.now(),
        assignee: trimmedAssignee.isEmpty ? null : trimmedAssignee,
      );
      cubit.addTask(task);
    } else {
      final task = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: trimmedDescription,
        status: _status,
        assignee: trimmedAssignee.isEmpty ? null : trimmedAssignee,
      );
      cubit.updateTask(task);
    }

    Navigator.of(context).pop();
  }
}
