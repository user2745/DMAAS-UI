import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card_new.dart';

class TaskColumn extends StatefulWidget {
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
  State<TaskColumn> createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.status.color.withAlpha(80);
    final highlightColor = widget.status.color.withAlpha(120);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        return details.data.status != widget.status;
      },
      onAcceptWithDetails: (details) {
        widget.onMove(details.data.id, widget.status);
        setState(() => _isDraggingOver = false);
      },
      onMove: (_) {
        if (!_isDraggingOver) {
          setState(() => _isDraggingOver = true);
        }
      },
      onLeave: (_) {
        setState(() => _isDraggingOver = false);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).cardColor.withAlpha(_isDraggingOver ? 255 : 230),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDraggingOver ? highlightColor : borderColor,
              width: _isDraggingOver ? 2.5 : 1.5,
            ),
            boxShadow: _isDraggingOver
                ? [
                    BoxShadow(
                      color: widget.status.color.withAlpha(60),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Flexible(
                child: widget.tasks.isEmpty
                    ? _EmptyColumn(status: widget.status)
                    : SingleChildScrollView(
                        child: Column(
                          children: widget.tasks
                              .map(
                                (task) => TaskCard(
                                  task: task,
                                  onMoveLeft: task.status.previous == null
                                      ? null
                                      : () => widget.onMove(
                                          task.id,
                                          task.status.previous!,
                                        ),
                                  onMoveRight: task.status.next == null
                                      ? null
                                      : () => widget.onMove(
                                          task.id,
                                          task.status.next!,
                                        ),
                                  onDelete: () => widget.onRemove(task.id),
                                  onEdit: () => widget.onEdit(task),
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: widget.status.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.status.color.withAlpha(100),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.status.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.status.color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.status.color.withAlpha(80),
              width: 1,
            ),
          ),
          child: Text(
            '${widget.tasks.length}',
            style: TextStyle(
              color: widget.status.color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Add to ${widget.status.label}',
          onPressed: widget.onAdd,
          icon: Icon(Icons.add_circle, color: widget.status.color),
          iconSize: 24,
        ),
      ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(30),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(100),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No items in ${status.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Drag tasks here or click + to add',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
