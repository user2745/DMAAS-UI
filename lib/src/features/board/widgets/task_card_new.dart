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
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: 0.8,
          child: _buildCardContent(context, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(context),
      ),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool isDragging = false}) {
    final borderColor = task.status.color.withAlpha(100);
    
    return Container(
      width: isDragging ? 260 : null,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withAlpha(240),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: task.status.color.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Status indicator bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      task.status.color,
                      task.status.color.withAlpha(150),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.status.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: task.status.color.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          task.status.label,
                          style: TextStyle(
                            color: task.status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_horiz,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 20,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: onEdit,
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (onMoveLeft != null)
                            PopupMenuItem(
                              onTap: onMoveLeft,
                              child: const Row(
                                children: [
                                  Icon(Icons.arrow_back, size: 18),
                                  SizedBox(width: 8),
                                  Text('Move Left'),
                                ],
                              ),
                            ),
                          if (onMoveRight != null)
                            PopupMenuItem(
                              onTap: onMoveRight,
                              child: const Row(
                                children: [
                                  Icon(Icons.arrow_forward, size: 18),
                                  SizedBox(width: 8),
                                  Text('Move Right'),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            onTap: onDelete,
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                        ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 13,
                            height: 1.4,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (task.assignee != null && task.assignee!.isNotEmpty)
                        _buildPill(
                          context,
                          icon: Icons.person_outline,
                          label: task.assignee!,
                          color: const Color(0xFF58A6FF),
                        ),
                      _buildPill(
                        context,
                        icon: Icons.schedule,
                        label: _timeAgo(task.createdAt),
                        color: const Color(0xFF8B949E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(100),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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
