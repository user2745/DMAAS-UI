import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../tasks_list/models/field.dart';
import '../models/task.dart';
import 'task_detail_modal.dart';
import '../../../widgets/micro_interactions/status_momentum.dart';
import '../../../widgets/micro_interactions/fade_delete_card.dart';
import '../../boost/view/boost_sheet.dart';

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
    final scale = (_isHovered && !isDragging) ? 1.015 : 1.0;

    // Flutter constraint: borderRadius requires uniform border colors.
    // Solution: uniform Border.all for the container, then a Positioned
    // left strip for the status accent, all clipped with ClipRRect.
    return Transform.scale(
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: isDragging ? 270 : null,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: (_isHovered || isDragging)
              ? [
                  BoxShadow(
                    color: statusColor.withAlpha(30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Card body: uniform border so borderRadius works
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF30363D), width: 1),
                ),
                // left: 17 = 3px accent + 14px inner gap; right: 6 for menu
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 13, 6, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.35,
                                color: const Color(0xFFE6EDF3),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildActionMenu(context),
                        ],
                      ),
                      // Description
                      if ((widget.task.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.task.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8B949E),
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Footer: time pill + field pills + drag dots
                      Row(
                        children: [
                          _buildTimePill(context),
                          ..._buildFieldPills(context).take(2).map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: p,
                                ),
                              ),
                          const Spacer(),
                          const Icon(
                            Icons.drag_indicator,
                            size: 16,
                            color: Color(0xFF30363D),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Left accent strip (status color)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: statusColor),
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
          value: 'boost',
          onTap: () => BoostSheet.show(
            context,
            taskId: widget.task.id,
            taskTitle: widget.task.title,
            taskDescription: widget.task.description,
          ),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Boost this task', style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFFBB86FC))),
            ],
          ),
        ),
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

  Widget _buildTimePill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 11, color: Color(0xFF8B949E)),
          const SizedBox(width: 3),
          Text(
            _timeAgo(widget.task.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8B949E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: fieldColor.withAlpha(18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fieldColor.withAlpha(60), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getFieldIcon(fieldType), size: 11, color: fieldColor),
            const SizedBox(width: 3),
            Flexible(
              child: Tooltip(
                message: '$fieldName: $fieldValue',
                child: Text(
                  fieldValue,
                  style: TextStyle(
                    color: fieldColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
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
