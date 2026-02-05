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
    final theme = Theme.of(context);
    final statusColor = widget.task.status.color;
    
    // Design Language: Elevation feedback (2px idle → 8px hover, 150ms)
    final elevation = (_isHovered || isDragging) ? 8.0 : 2.0;
    final shadowBlur = (_isHovered || isDragging) ? 20.0 : 12.0;
    final scale = (_isHovered && !isDragging) ? 1.02 : 1.0;

    // Design Language: Smooth elevation animation using AnimatedContainer
    return Transform.scale(
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: isDragging ? 260 : null,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withAlpha(_isHovered ? 180 : 80),
            width: _isHovered ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withAlpha((_isHovered || isDragging) ? 50 : 20),
              blurRadius: shadowBlur,
              offset: Offset(0, elevation),
              spreadRadius: (_isHovered || isDragging) ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Top accent bar (gradient)
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        statusColor,
                        statusColor.withAlpha(200),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Status badge & menu
                    Row(
                      children: [
                        // Status badge with improved design
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withAlpha(100),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Action menu
                        _buildActionMenu(context),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Title with improved sizing
                    Text(
                      widget.task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Description (if exists)
                    if ((widget.task.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.task.description ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Field values and metadata pills
                    if (_buildFieldPills(context).isNotEmpty || true) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            // Created time pill
                            _buildMetadataPill(
                              context,
                              icon: Icons.schedule,
                              label: _timeAgo(widget.task.createdAt),
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              textColor: theme.colorScheme.onSecondaryContainer,
                            ),
                            // Field pills
                            ..._buildFieldPills(context),
                          ],
                        ),
                      ),
                    ],
                    
                    // Drag indicator at bottom
                    const SizedBox(height: 8),
                    Center(
                      child: Icon(
                        Icons.drag_indicator,
                        color: theme.colorScheme.outline.withOpacity(0.4),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurfaceVariant,
        size: 18,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          onTap: widget.onEdit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text('Edit', style: theme.textTheme.labelMedium),
            ],
          ),
        ),
        if (widget.onMoveLeft != null) ...[
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'moveLeft',
            onTap: widget.onMoveLeft,
            child: Row(
              children: [
                Icon(Icons.arrow_back, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Move Left', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ],
        if (widget.onMoveRight != null) ...[
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'moveRight',
            onTap: widget.onMoveRight,
            child: Row(
              children: [
                Icon(Icons.arrow_forward, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Move Right', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ],
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          onTap: widget.onDelete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ],
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
          _buildFieldPill(
            context,
            fieldName: field.name,
            fieldValue: displayValue,
            fieldType: field.type,
            fieldColor: field.color,
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

  Widget _buildFieldPill(
    BuildContext context, {
    required String fieldName,
    required String fieldValue,
    required FieldType fieldType,
    required Color fieldColor,
  }) {
    final theme = Theme.of(context);
    final icon = _getFieldIcon(fieldType);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: fieldColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fieldColor.withAlpha(80),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fieldColor),
          const SizedBox(width: 3),
          Tooltip(
            message: '$fieldName: $fieldValue',
            child: Text(
              fieldValue,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fieldColor,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withAlpha(60),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
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
