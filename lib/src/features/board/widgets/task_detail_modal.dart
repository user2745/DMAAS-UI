import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task.dart';
import '../cubit/task_board_cubit.dart';

class TaskDetailModal extends StatefulWidget {
  const TaskDetailModal({
    super.key,
    required this.task,
  });

  final Task task;

  static Future<void> show(BuildContext context, {required Task task}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return TaskDetailModal(task: task);
      },
    );
  }

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  late bool _isEditing;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskStatus _status;
  late DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
      TextEditingController(text: widget.task.description ?? '');
    _status = widget.task.status;
    _dueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _status.color.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _status.color.withAlpha(50),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close and edit buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _status.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isEditing
                        ? TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'Task title',
                              border: UnderlineInputBorder(),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          )
                        : Text(
                            _titleController.text,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                    ),
                  if (_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = false),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel',
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                ],
              ),
            ),
            Divider(color: Colors.grey.withAlpha(50)),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    if (_isEditing) ...[
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<TaskStatus>(
                        value: _status,
                        isExpanded: true,
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
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _status.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status.label,
                          style: TextStyle(
                            color: _status.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Task description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          _descriptionController.text.isEmpty
                              ? 'No description'
                              : _descriptionController.text,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                height: 1.6,
                              ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Details
                    if (_isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _dueDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _dueDate == null
                                  ? 'Set Due Date'
                                  : _formatDate(_dueDate!),
                            ),
                          ),
                          if (_dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () =>
                                    setState(() => _dueDate = null),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Clear Due Date'),
                              ),
                            ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildDetailItem(
                            context,
                            icon: Icons.calendar_today_outlined,
                            label: 'Created',
                            value: _formatDate(widget.task.createdAt),
                            color: const Color(0xFFBB86FC),
                          ),
                          if (_dueDate != null)
                            _buildDetailItem(
                              context,
                              icon: Icons.event_outlined,
                              label: 'Due Date',
                              value: _formatDate(_dueDate!),
                              color: const Color(0xFFFF9800),
                            ),
                        ],
                      ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 20),
                      // Metadata
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withAlpha(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task ID',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              widget.task.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _status.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _titleController.text = widget.task.title;
                            _descriptionController.text =
                              widget.task.description ?? '';
                          _status = widget.task.status;
                          _dueDate = widget.task.dueDate;
                          setState(() => _isEditing = false);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final cubit = context.read<TaskBoardCubit>();
    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      dueDate: _dueDate,
    );
    cubit.updateTask(updatedTask);
    setState(() => _isEditing = false);
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
