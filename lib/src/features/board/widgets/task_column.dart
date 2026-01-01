import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card.dart';

class TaskColumn extends StatelessWidget {
  const TaskColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onAdd,
    required this.onMove,
    required this.onRemove,
    required this.onEdit,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final VoidCallback onAdd;
  final void Function(String taskId, TaskStatus toStatus) onMove;
  final void Function(String taskId) onRemove;
  final void Function(Task task) onEdit;

  @override
  Widget build(BuildContext context) {
    final borderColor = status.color.withAlpha(64);
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 12,
                width: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                status.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${tasks.length}'),
                backgroundColor: status.color.withAlpha(31),
                labelStyle: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Add to ${status.label}',
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            _EmptyColumn(status: status)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onMoveLeft: task.status.previous == null
                      ? null
                      : () => onMove(task.id, task.status.previous!),
                  onMoveRight: task.status.next == null
                      ? null
                      : () => onMove(task.id, task.status.next!),
                  onDelete: () => onRemove(task.id),
                  onEdit: () => onEdit(task),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            'No items in ${status.label}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Add a task to get started.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
