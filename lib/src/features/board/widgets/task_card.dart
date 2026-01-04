import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onDelete,
    required this.onEdit,
  });

  final Task task;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if ((task.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _StatusChip(status: task.status),
                Chip(
                  label: Text('Created ${_timeAgo(task.createdAt)}'),
                  avatar: const Icon(Icons.schedule, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: onMoveLeft == null ? 'Blocked' : 'Move left',
                  onPressed: onMoveLeft,
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: _actionColor(context, onMoveLeft),
                  ),
                ),
                IconButton(
                  tooltip: onMoveRight == null ? 'Blocked' : 'Move right',
                  onPressed: onMoveRight,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: _actionColor(context, onMoveRight),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(BuildContext context, VoidCallback? action) {
    if (action == null) {
      return Colors.grey.shade400;
    }
    return Theme.of(context).colorScheme.primary;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      backgroundColor: status.color.withAlpha(36),
      labelStyle: TextStyle(color: status.color, fontWeight: FontWeight.w700),
    );
  }
}

String _timeAgo(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  return '${diff.inDays}d ago';
}
