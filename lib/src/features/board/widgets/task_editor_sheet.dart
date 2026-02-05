import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks_list/models/field.dart';
import '../cubit/task_board_cubit.dart';
import '../models/task.dart';
import '../../../widgets/animated_focus_text_field.dart';

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    super.key,
    this.task,
    this.initialStatus,
    this.fields = const [],
  });

  final Task? task;
  final TaskStatus? initialStatus;
  final List<Field> fields;

  static Future<void> show(
    BuildContext context, {
    Task? task,
    TaskStatus? initialStatus,
    List<Field> fields = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: TaskEditorSheet(
            task: task,
            initialStatus: initialStatus,
            fields: fields,
          ),
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
  late TaskStatus _status;
  late DateTime? _dueDate;
  late Map<String, TextEditingController> _textControllers;
  late Map<String, String?> _singleSelectValues;
  late Map<String, DateTime?> _dateValues;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _status = widget.task?.status ?? widget.initialStatus ?? TaskStatus.todo;
    _dueDate = widget.task?.dueDate;
    
    // Initialize field controllers
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEditing ? 'Update Task' : 'New Task',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Title input
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
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Add a task title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: theme.textTheme.bodyMedium,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please add a title';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description input
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
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Add details...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 3,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Status dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TaskStatus>(
                      initialValue: _status,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: TaskStatus.values
                          .map(
                            (s) => DropdownMenuItem<TaskStatus>(
                              value: s,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.color.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.label,
                                  style: TextStyle(
                                    color: s.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
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
                          _dueDate != null
                              ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                              : 'Not set',
                          style: theme.textTheme.labelMedium,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _dueDate = null);
                                },
                                iconSize: 18,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _pickDate(context),
                              iconSize: 18,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Custom Fields
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
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _submit(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isEditing ? Icons.save_outlined : Icons.add_task, size: 18),
                            const SizedBox(width: 8),
                            Text(isEditing ? 'Save' : 'Create'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? now,
                          firstDate: now.subtract(const Duration(days: 365 * 5)),
                          lastDate: now.add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() {
                            _dateValues[field.id] = date;
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
        );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<TaskBoardCubit>();
    final trimmedTitle = _titleController.text.trim();
    final trimmedDescription = _descriptionController.text.trim();
    
    // Collect field values
    final fieldValues = _collectFieldValues();

    if (widget.task == null) {
      cubit.addTask(
        title: trimmedTitle,
        description: trimmedDescription.isEmpty ? null : trimmedDescription,
        dueDate: _dueDate,
        fieldValues: fieldValues,
      );
    } else {
      final task = widget.task!.copyWith(
        title: trimmedTitle,
        description: trimmedDescription.isEmpty ? null : trimmedDescription,
        status: _status,
        dueDate: _dueDate,
      );
      cubit.updateTask(task);
    }

    Navigator.of(context).pop();
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
}
