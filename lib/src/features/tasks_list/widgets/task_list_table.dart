import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../board/models/task.dart';
import '../cubit/tasks_list_cubit.dart';
import '../models/field.dart';
import '../widgets/field_widgets.dart';

class TaskListTable extends StatefulWidget {
  const TaskListTable({
    super.key,
    required this.tasks,
    required this.fields,
    required this.taskFieldById,
    required this.taskFieldValuesByTaskId,
    required this.sortKey,
    required this.sortAscending,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    required this.onAddField,
    required this.onSortChanged,
    required this.onAddTask,
    required this.onReorder,
    this.onFieldValueChange,
  });

  final List<Task> tasks;
  final List<Field> fields;
  final Map<String, String?> taskFieldById;
  final Map<String, Map<String, Object?>> taskFieldValuesByTaskId;
  final TaskSortKey sortKey;
  final bool sortAscending;
  final Function(Task) onTaskUpdate;
  final Function(String) onTaskDelete;
  final VoidCallback onAddField;
  final void Function(TaskSortKey) onSortChanged;
  final Function(String title) onAddTask;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String taskId, String fieldId, Object? value)?
  onFieldValueChange;

  @override
  State<TaskListTable> createState() => _TaskListTableState();
}

class _TaskListTableState extends State<TaskListTable> {
  int? _hoveredRowIndex;
  bool _isAddingTask = false;
  late TextEditingController _newTaskController;
  final FocusNode _newTaskFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _newTaskController = TextEditingController();
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    _newTaskFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM d, yyyy').format(date);
  }

  ({String label, Color color}) _derivedStatus(Task task) {
    if (task.status == TaskStatus.done) {
      return (label: 'Completed', color: const Color(0xFF3FB950));
    }
    final now = DateTime.now();
    if (task.dueDate != null) {
      if (task.dueDate!.isBefore(now)) {
        return (label: 'Delayed', color: const Color(0xFFEF4444));
      }
      return (label: 'Upcoming', color: const Color(0xFF8B5CF6));
    }
    if (task.status == TaskStatus.inProgress) {
      return (label: 'In Progress', color: const Color(0xFF58A6FF));
    }
    return (label: 'To Do', color: const Color(0xFF58A6FF));
  }

  double get _tableWidth {
    // Drag handle/index + title + assignees + status + due date + actions + add-field + padding
    const baseWidth = 48 + 280 + 150 + 140 + 140 + 100 + 40 + 24;
    return baseWidth + (widget.fields.length * 140);
  }

  Widget _headerCell({
    required String label,
    required double width,
    TaskSortKey? sortKey,
    VoidCallback? onTap,
  }) {
    final isActive = sortKey != null && widget.sortKey == sortKey;
    final icon = isActive
        ? Icon(
            widget.sortAscending
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down,
            size: 18,
            color: Colors.grey[700],
          )
        : null;

    final content = Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (icon != null) icon,
      ],
    );

    if (onTap == null) {
      return SizedBox(width: width, child: content);
    }

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '#',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    _headerCell(
                      label: 'Title',
                      width: 280,
                      sortKey: TaskSortKey.title,
                      onTap: () => widget.onSortChanged(TaskSortKey.title),
                    ),
                    _headerCell(label: 'Assignees', width: 150),
                    _headerCell(
                      label: 'Status',
                      width: 140,
                      sortKey: TaskSortKey.status,
                      onTap: () => widget.onSortChanged(TaskSortKey.status),
                    ),
                    _headerCell(
                      label: 'Due Date',
                      width: 140,
                      sortKey: TaskSortKey.dueDate,
                      onTap: () => widget.onSortChanged(TaskSortKey.dueDate),
                    ),
                    _headerCell(label: 'Actions', width: 100),
                    ...widget.fields.map((field) {
                      return SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                field.name,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: field.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              tooltip: 'Field options',
                              offset: const Offset(0, 40),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'sort_asc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_upward, size: 16, color: Colors.grey[700]),
                                      const SizedBox(width: 8),
                                      const Text('Sort A → Z'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'sort_desc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_downward, size: 16, color: Colors.grey[700]),
                                      const SizedBox(width: 8),
                                      const Text('Sort Z → A'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
                                      const SizedBox(width: 8),
                                      const Text('Edit Field'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text('Delete Field', style: TextStyle(color: Colors.red[700])),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'sort_asc':
                                    _sortByField(field.id, ascending: true);
                                    break;
                                  case 'sort_desc':
                                    _sortByField(field.id, ascending: false);
                                    break;
                                  case 'edit':
                                    _showEditFieldDialog(context, field);
                                    break;
                                  case 'delete':
                                    _showDeleteFieldConfirmation(context, field);
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(
                      width: 40,
                      child: Tooltip(
                        message: 'Add field',
                        child: IconButton(
                          icon: Icon(Icons.add, size: 18, color: Colors.grey[400]),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: widget.onAddField,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: widget.onReorder,
                itemCount: widget.tasks.length,
                itemBuilder: (context, index) {
                  final task = widget.tasks[index];
                  final fieldId = widget.taskFieldById[task.id];
                  final isHovered = _hoveredRowIndex == index;
                  final ds = _derivedStatus(task);

                  return MouseRegion(
                    key: ValueKey(task.id),
                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isHovered ? const Color(0xFFFAFAFA) : Colors.white,
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_indicator,
                                    size: 18,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: _AssigneesCell(
                              taskId: task.id,
                              onAdd: () async {
                                final assignee = await _promptAssignee(context);
                                if (assignee != null) {
                                  // Assignee assignment will be handled separately
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: PopupMenuButton<TaskStatus>(
                              tooltip: 'Change status',
                              offset: const Offset(0, 40),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: TaskStatus.todo,
                                  child: Text('To Do'),
                                ),
                                PopupMenuItem(
                                  value: TaskStatus.inProgress,
                                  child: Text('In Progress'),
                                ),
                                PopupMenuItem(
                                  value: TaskStatus.done,
                                  child: Text('Done'),
                                ),
                              ],
                              onSelected: (newStatus) {
                                final updatedTask = task.copyWith(status: newStatus);
                                widget.onTaskUpdate(updatedTask);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ds.color.withOpacity(0.08),
                                  border: Border.all(
                                    color: ds.color.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ds.label,
                                        style: TextStyle(
                                          color: ds.color,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: ds.color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: task.dueDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  widget.onTaskUpdate(task.copyWith(dueDate: picked));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatDate(task.dueDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isHovered)
                                  Tooltip(
                                    message: 'Edit',
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _showEditTaskDialog(
                                            context,
                                            task,
                                            fieldId,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                if (isHovered)
                                  Tooltip(
                                    message: 'Delete',
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _showDeleteConfirmation(context, task.id);
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ...widget.fields.map((field) {
                            final value =
                                widget.taskFieldValuesByTaskId[task.id]?[field.id];

                            return SizedBox(
                              width: 140,
                              child: _buildFieldCell(
                                task: task,
                                field: field,
                                value: value,
                              ),
                            );
                          }),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _buildQuickAddRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddRow() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '${widget.tasks.length + 1}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
          SizedBox(
            width: 280,
            child: _isAddingTask
                ? _InlineTaskEditor(
                    controller: _newTaskController,
                    focusNode: _newTaskFocusNode,
                    onChanged: (_) => setState(() {}),
                    onSubmit: (title) {
                      if (title.isNotEmpty) {
                        widget.onAddTask(title);
                        setState(() {
                          _isAddingTask = false;
                          _newTaskController.clear();
                        });
                      }
                    },
                    onCancel: () {
                      setState(() {
                        _isAddingTask = false;
                        _newTaskController.clear();
                      });
                    },
                    title: _newTaskController.text,
                  )
                : InkWell(
                    onTap: () {
                      setState(() {
                        _isAddingTask = true;
                      });
                      Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _newTaskFocusNode.requestFocus(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add new task...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 150),
          const SizedBox(width: 140),
          const SizedBox(width: 140),
          const SizedBox(width: 100),
          ...widget.fields.map((_) => const SizedBox(width: 140)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildFieldCell({
    required Task task,
    required Field field,
    required Object? value,
  }) {
    switch (field.type) {
      case FieldType.text:
        return _TextFieldCell(
          value: value?.toString(),
          onChanged: (newValue) {
            widget.onFieldValueChange?.call(task.id, field.id, newValue);
          },
        );
      case FieldType.singleSelect:
        return _SingleSelectFieldCell(
          value: value?.toString(),
          options: field.options,
          color: field.color,
          onChanged: (newValue) {
            widget.onFieldValueChange?.call(task.id, field.id, newValue);
          },
        );
      case FieldType.date:
        DateTime? dateValue;
        if (value is DateTime) {
          dateValue = value;
        } else if (value is String) {
          dateValue = DateTime.tryParse(value);
        }
        return _DateFieldCell(
          value: dateValue,
          onChanged: (newValue) {
            widget.onFieldValueChange?.call(task.id, field.id, newValue);
          },
        );
    }
  }

  void _showEditTaskDialog(
    BuildContext context,
    Task task,
    String? initialCategoryId,
  ) {
    showDialog(
      context: context,
      builder: (context) => TaskEditDialog(
        task: task,
        fields: widget.fields,
        initialFieldId: initialCategoryId,
        onSave: (updatedTask, fieldId) {
          widget.onTaskUpdate(updatedTask);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<_AssigneeInput?> _promptAssignee(BuildContext context) async {
    return showDialog<_AssigneeInput>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Assign User'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context, _AssigneeInput(name: name));
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onTaskDelete(taskId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sortByField(String fieldId, {required bool ascending}) {
    // TODO: Implement custom field sorting in TasksListCubit
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sorting by custom field (${ascending ? "A→Z" : "Z→A"})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditFieldDialog(BuildContext context, Field field) {
    showDialog(
      context: context,
      builder: (context) => CreateFieldDialog(initialField: field),
    );
  }

  void _showDeleteFieldConfirmation(BuildContext context, Field field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text(
          'Are you sure you want to delete "${field.name}"?\n\n'
          'Field values will be preserved in tasks but the column will be hidden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TasksListCubit>().deleteField(field.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class TaskEditDialog extends StatefulWidget {
  const TaskEditDialog({
    super.key,
    required this.task,
    required this.fields,
    required this.initialFieldId,
    required this.onSave,
  });

  final Task task;
  final List<Field> fields;
  final String? initialFieldId;
  final Function(Task, String?) onSave;

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskStatus _selectedStatus;
  late String? _selectedFieldId;
  late DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _selectedStatus = widget.task.status;
    _selectedFieldId = widget.initialFieldId;
    _selectedDueDate = widget.task.dueDate;
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
      title: const Text('Edit Task'),
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
            // Category selection is hidden in this UI version
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: TaskStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(
                _selectedDueDate != null
                    ? DateFormat('MMM d, yyyy').format(_selectedDueDate!)
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

            final updatedTask = widget.task.copyWith(
              title: title,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              status: _selectedStatus,
              dueDate: _selectedDueDate,
            );

            widget.onSave(updatedTask, _selectedFieldId);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AssigneeInput {
  final String name;
  _AssigneeInput({required this.name});
}

// Custom field cell widgets
class _TextFieldCell extends StatefulWidget {
  const _TextFieldCell({required this.value, required this.onChanged});

  final String? value;
  final Function(String?) onChanged;

  @override
  State<_TextFieldCell> createState() => _TextFieldCellState();
}

class _TextFieldCellState extends State<_TextFieldCell> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isEditing) {
      final newValue = _controller.text.trim();
      widget.onChanged(newValue.isEmpty ? null : newValue);
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: Colors.grey[700], fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        onSubmitted: (_) => _submit(),
        onTapOutside: (_) => _submit(),
      );
    }

    return InkWell(
      onTap: () => setState(() => _isEditing = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          widget.value?.isEmpty ?? true ? '-' : widget.value!,
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
      ),
    );
  }
}

class _SingleSelectFieldCell extends StatelessWidget {
  const _SingleSelectFieldCell({
    required this.value,
    required this.options,
    required this.color,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final Color color;
  final Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        value ?? '-',
        style: TextStyle(color: Colors.grey[700], fontSize: 13),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Select option',
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('Clear', style: TextStyle(color: Colors.grey[600])),
        ),
        ...options.map((option) {
          return PopupMenuItem(value: option, child: Text(option));
        }),
      ],
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: value != null ? color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                value ?? '-',
                style: TextStyle(
                  color: value != null ? color : Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class _DateFieldCell extends StatelessWidget {
  const _DateFieldCell({required this.value, required this.onChanged});

  final DateTime? value;
  final Function(DateTime?) onChanged;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(value),
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class _AssigneesCell extends StatelessWidget {
  const _AssigneesCell({required this.taskId, required this.onAdd});

  final String taskId;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          tooltip: 'Assign',
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _InlineTaskEditor extends StatefulWidget {
  const _InlineTaskEditor({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onCancel,
    required this.title,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(String) onSubmit;
  final VoidCallback onCancel;
  final String title;

  @override
  State<_InlineTaskEditor> createState() => _InlineTaskEditorState();
}

class _InlineTaskEditorState extends State<_InlineTaskEditor> {
  late OverlayEntry? _overlayEntry;
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _showOptionsOverlay();
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _showOptionsOverlay() {
    final renderBox =
        _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + 56,
          width: 280,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade400, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Create "${widget.title}"',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.title.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Start typing to create a task',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _editorKey,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(5),
        color: Colors.blue.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: 'Add new task...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: widget.onChanged,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  widget.onSubmit(value);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.check, size: 16),
                    color: Colors.blue.shade400,
                    padding: EdgeInsets.zero,
                    onPressed: widget.controller.text.isNotEmpty
                        ? () => widget.onSubmit(widget.controller.text)
                        : null,
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: Colors.grey[500],
                    padding: EdgeInsets.zero,
                    onPressed: widget.onCancel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
