import 'package:flutter/material.dart';

import '../../tasks_list/models/field.dart';
import '../models/task.dart';
import '../utils/drop_position_calculator.dart';
import 'drag_gate_widget.dart';
import 'task_card_new.dart';

class TaskColumn extends StatefulWidget {
  const TaskColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onAdd,
    required this.onMove,
    required this.onReorder,
    required this.onRemove,
    required this.onEdit,
    this.fields = const [],
    this.isReorderInFlight = false,
    this.onCollapse,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final VoidCallback onAdd;
  final void Function(String taskId, TaskStatus toStatus) onMove;
  final void Function(String taskId, TaskStatus toStatus, int toIndex) onReorder;
  final void Function(String taskId) onRemove;
  final void Function(Task task) onEdit;
  final List<Field> fields;
  final bool isReorderInFlight;
  final VoidCallback? onCollapse;

  @override
  State<TaskColumn> createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  bool _isDraggingOver = false;
  int? _dropIndex;
  String? _draggedTaskId;
  final Map<String, GlobalKey> _cardKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  /// Get or create a GlobalKey for a task by its ID
  GlobalKey _keyForTask(String taskId) {
    return _cardKeys.putIfAbsent(taskId, () => GlobalKey());
  }

  /// Clean up keys for tasks that no longer exist
  void _pruneStaleKeys() {
    final currentIds = widget.tasks.map((t) => t.id).toSet();
    _cardKeys.removeWhere((id, _) => !currentIds.contains(id));
  }

  @override
  void didUpdateWidget(TaskColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneStaleKeys();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.status.color.withAlpha(80);
    final highlightColor = widget.status.color.withAlpha(120);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        // Accept both cross-column and within-column drops
        // Disable if reorder is in flight
        return !widget.isReorderInFlight;
      },
      onAcceptWithDetails: (details) {
        final fromStatus = details.data.status;
        final toStatus = widget.status;
        final toIndex = _dropIndex ?? widget.tasks.length;
        
        if (fromStatus != toStatus) {
          // Cross-column move
          widget.onMove(details.data.id, toStatus);
        } else if (fromStatus == toStatus && _dropIndex != null) {
          // Within-column reorder
          widget.onReorder(details.data.id, toStatus, toIndex);
        }
        
        setState(() {
          _isDraggingOver = false;
          _dropIndex = null;
          _draggedTaskId = null;
        });
      },
      onMove: (details) {
        if (!widget.isReorderInFlight) {
          // Store the dragged task ID
          _draggedTaskId = details.data.id;
          
          // Calculate drop index based on closest card proximity
          _dropIndex = _calculateDropIndex(details.offset);
          
          if (!_isDraggingOver) {
            setState(() => _isDraggingOver = true);
          } else {
            setState(() {}); // Rebuild to update drop indicator position
          }
        }
      },
      onLeave: (_) {
        setState(() {
          _isDraggingOver = false;
          _dropIndex = null;
          _draggedTaskId = null;
        });
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
                    : DragGateWidget(
                        child: RawScrollbar(
                          thickness: 6,
                          radius: const Radius.circular(3),
                          thumbColor: Colors.grey.withOpacity(0.4),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              children: _buildTaskCards(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds task card list with a placeholder indicator at the drop position
  List<Widget> _buildTaskCards() {
    final cards = <Widget>[];
    final tasks = widget.tasks;
    final isDraggingInThisColumn = _draggedTaskId != null &&
        tasks.any((t) => t.id == _draggedTaskId);

    // _dropIndex is the insertion position among VISIBLE (non-dragged) cards.
    // We need to map that back to a slot in the original list.
    //
    // Walk through the original list. For each non-dragged card, track its
    // "visible index" (position among visible cards). Insert the placeholder
    // when visibleIndex reaches _dropIndex.

    int visibleIndex = 0;
    bool placeholderInserted = false;

    void maybeInsertPlaceholder() {
      if (!placeholderInserted &&
          _dropIndex != null &&
          visibleIndex == _dropIndex) {
        placeholderInserted = true;
        cards.add(
          AnimatedContainer(
            key: const ValueKey('__drop_placeholder__'),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: widget.status.color.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.status.color.withAlpha(100),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.drag_handle,
                color: widget.status.color.withAlpha(120),
                size: 20,
              ),
            ),
          ),
        );
      }
    }

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final isDraggedCard =
          isDraggingInThisColumn && task.id == _draggedTaskId;

      if (isDraggedCard) {
        // Dragged card: collapse to 0 height so it disappears in-place
        cards.add(
          AnimatedContainer(
            key: _keyForTask(task.id),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: TaskCard(
              task: task,
              fields: widget.fields,
              onMoveLeft: null,
              onMoveRight: null,
              onDelete: () => widget.onRemove(task.id),
              onEdit: () => widget.onEdit(task),
            ),
          ),
        );
        // Don't increment visibleIndex — this card is hidden
        continue;
      }

      // Before this visible card, maybe insert placeholder
      maybeInsertPlaceholder();

      // Normal visible card
      cards.add(
        KeyedSubtree(
          key: _keyForTask(task.id),
          child: TaskCard(
            task: task,
            fields: widget.fields,
            onMoveLeft: task.status.previous == null
                ? null
                : () => widget.onMove(task.id, task.status.previous!),
            onMoveRight: task.status.next == null
                ? null
                : () => widget.onMove(task.id, task.status.next!),
            onDelete: () => widget.onRemove(task.id),
            onEdit: () => widget.onEdit(task),
          ),
        ),
      );

      visibleIndex++;
    }

    // Placeholder at the end (after all visible cards)
    maybeInsertPlaceholder();

    return cards;
  }

  /// Calculates the drop index among VISIBLE (non-dragged) cards.
  ///
  /// Skips the dragged card's collapsed rect entirely so it doesn't
  /// corrupt position calculations.
  int _calculateDropIndex(Offset dragOffset) {
    // Collect rects of only the VISIBLE cards (skip the dragged one)
    final visibleRects = <Rect>[];
    for (final task in widget.tasks) {
      if (task.id == _draggedTaskId && task.status == widget.status) {
        continue; // skip collapsed card
      }
      final key = _cardKeys[task.id];
      if (key == null) continue;
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.size.height > 1) {
        final pos = renderBox.localToGlobal(Offset.zero);
        visibleRects.add(pos & renderBox.size);
      }
    }

    if (visibleRects.isEmpty) return 0;

    return DropPositionCalculator.calculate(
      dragY: dragOffset.dy,
      visibleCardRects: visibleRects,
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
        if (widget.onCollapse != null)
          IconButton(
            tooltip: 'Collapse column',
            onPressed: widget.onCollapse,
            icon: Icon(
              Icons.chevron_left,
              color: widget.status.color.withAlpha(180),
            ),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
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
