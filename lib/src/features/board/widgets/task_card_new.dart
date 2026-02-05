import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../tasks_list/models/field.dart';
import '../models/task.dart';
import 'task_detail_modal.dart';
import '../../../widgets/micro_interactions/status_momentum.dart';
import '../../../widgets/micro_interactions/fade_delete_card.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onDelete,
    required this.onEdit,
    this.fields = const [],
  });

  final Task task;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final List<Field> fields;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return FadeDeleteCard(
      onDelete: widget.onDelete,
      onUndo: () {
        // Optionally restore the task (if backend supports it)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task restored')),
        );
      },
      child: Draggable<Task>(
        data: widget.task,
        onDragStarted: () => setState(() => _isDragging = true),
        onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
        onDragEnd: (_) => setState(() => _isDragging = false),
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: 0.8,
            child: _buildCardContent(context, isDragging: true),
          ),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: GestureDetector(
          onTap: () => TaskDetailModal.show(context, task: widget.task),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: StatusMomentum(
              status: widget.task.status,
              isDragging: _isDragging,
              child: _buildCardContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool isDragging = false}) {
    final borderColor = widget.task.status.color.withAlpha(100);
    // Design Language: Elevation feedback (2px idle → 8px hover, 150ms)
    final elevation = (_isHovered || isDragging) ? 8.0 : 2.0;
    final shadowBlur = (_isHovered || isDragging) ? 16.0 : 12.0;

    // Design Language: Smooth elevation animation using AnimatedContainer
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: isDragging ? 260 : null,
      margin: const EdgeInsets.only(bottom: 12),
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
            color: widget.task.status.color.withAlpha(30),
            blurRadius: shadowBlur,
            offset: Offset(0, elevation),
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
                      widget.task.status.color,
                      widget.task.status.color.withAlpha(150),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                          color: widget.task.status.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.task.status.color.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.task.status.label,
                          style: TextStyle(
                            color: widget.task.status.color,
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
                            onTap: widget.onEdit,
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (widget.onMoveLeft != null)
                          PopupMenuItem(
                            onTap: widget.onMoveLeft,
                              child: const Row(
                                children: [
                                  Icon(Icons.arrow_back, size: 18),
                                  SizedBox(width: 8),
                                  Text('Move Left'),
                                ],
                              ),
                            ),
                          if (widget.onMoveRight != null)
                          PopupMenuItem(
                            onTap: widget.onMoveRight,
                              child: const Row(
                                children: [
                                  Icon(Icons.arrow_forward, size: 18),
                                  SizedBox(width: 8),
                                  Text('Move Right'),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            onTap: widget.onDelete,
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  if ((widget.task.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.task.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPill(
                        context,
                        icon: Icons.schedule,
                        label: _timeAgo(widget.task.createdAt),
                        color: const Color(0xFF8B949E),
                      ),
                      ..._buildFieldPills(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withAlpha(100),
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

  List<Widget> _buildFieldPills(BuildContext context) {
     if (widget.task.fieldValues == null || widget.task.fieldValues!.isEmpty) {
      return [];
    }

    final pills = <Widget>[];
    for (final field in widget.fields) {
      final value = widget.task.fieldValues![field.id];
      if (value != null) {
        String displayValue;
        if (field.type == FieldType.date) {
          final date = value is DateTime
              ? value
              : (value is String ? DateTime.tryParse(value) : null);
          displayValue = date != null
              ? DateFormat('MMM d').format(date)
              : value.toString();
        } else {
          displayValue = value.toString();
        }

        pills.add(
          _buildPill(
            context,
            icon: _getFieldIcon(field.type),
            label: '${field.name}: $displayValue',
            color: field.color,
          ),
        );
      }
    }
    return pills;
  }

  IconData _getFieldIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.text_fields;
      case FieldType.singleSelect:
        return Icons.check_circle_outline;
      case FieldType.date:
        return Icons.calendar_today;
    }
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
