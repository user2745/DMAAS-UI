import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../board/models/task.dart';

class TaskDetailsDialog extends StatelessWidget {
  const TaskDetailsDialog({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.flag,
              label: 'Status',
              value: task.status.label,
              color: task.status.color,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'Created',
              value: _formatDateTime(task.createdAt),
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.event,
                label: 'Due Date',
                value: _formatDateTime(task.dueDate!),
                color: _getDueDateColor(task.dueDate!),
              ),
            ],
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                const SizedBox(width: 8),
                if (onEdit != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit?.call();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy · h:mm a').format(date);
  }

  Color? _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return const Color(0xFFEF4444); // Red for overdue
    } else if (dueDate.difference(now).inDays <= 1) {
      return const Color(0xFFFF9800); // Orange for due soon
    }
    return null;
  }
}
