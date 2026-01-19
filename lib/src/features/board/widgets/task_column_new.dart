import 'package:flutter/material.dart';

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
    this.isReorderInFlight = false,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final VoidCallback onAdd;
  final void Function(String taskId, TaskStatus toStatus) onMove;
  final void Function(String taskId, TaskStatus toStatus, int toIndex) onReorder;
  final void Function(String taskId) onRemove;
  final void Function(Task task) onEdit;
  final bool isReorderInFlight;

  @override
  State<TaskColumn> createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  bool _isDraggingOver = false;
  int? _dropIndex;
  String? _draggedTaskId;
  final List<GlobalKey> _cardKeys = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateCardKeys();
  }

  @override
  void didUpdateWidget(TaskColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks.length != widget.tasks.length) {
      _updateCardKeys();
    }
  }

  void _updateCardKeys() {
    _cardKeys.clear();
    for (int i = 0; i < widget.tasks.length; i++) {
      _cardKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns the tasks list with live reordering during drag
  List<Task> _getLiveReorderedTasks() {
    if (_draggedTaskId == null || _dropIndex == null) {
      return widget.tasks;
    }
    
    // Find the dragged task
    final draggedTask = widget.tasks.firstWhere(
      (t) => t.id == _draggedTaskId,
      orElse: () => widget.tasks.first,
    );
    
    // If dragging from same column, create temporary reordered list
    if (draggedTask.status == widget.status) {
      final reordered = List<Task>.from(widget.tasks);
      reordered.removeWhere((t) => t.id == _draggedTaskId);
      
      // Insert at drop index
      final insertIndex = _dropIndex!.clamp(0, reordered.length);
      reordered.insert(insertIndex, draggedTask);
      
      return reordered;
    }
    
    return widget.tasks;
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

  /// Builds task card list with live reordering animation
  List<Widget> _buildTaskCards() {
    final cards = <Widget>[];
    
    // Use live reordered list during drag
    final displayTasks = _getLiveReorderedTasks();
    
    for (int i = 0; i < displayTasks.length; i++) {
      final task = displayTasks[i];
      
      // Determine if this is the dragged card
      final isDraggedCard = task.id == _draggedTaskId && 
                           task.status == widget.status;
      
      cards.add(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: _cardKeys.length > i ? _cardKeys[i] : null,
            child: Opacity(
              key: ValueKey('${task.id}_${i}'),
              opacity: isDraggedCard ? 0.3 : 1.0,
              child: TaskCard(
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
            ),
          ),
        ),
      );
    }
    
    return cards;
  }

  /// Calculates the drop index based on drag offset using actual card positions
  int _calculateDropIndex(Offset dragOffset) {
    if (widget.tasks.isEmpty) return 0;
    
    // Get actual card positions from the live reordered list
    final displayTasks = _getLiveReorderedTasks();
    final cardPositions = <Rect>[];
    
    for (final key in _cardKeys) {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        cardPositions.add(position & renderBox.size);
      }
    }
    
    if (cardPositions.isEmpty) {
      // Fallback: use drag Y relative to column
      final columnBox = context.findRenderObject() as RenderBox?;
      if (columnBox != null) {
        final localOffset = columnBox.globalToLocal(dragOffset);
        final relativePosition = localOffset.dy / columnBox.size.height;
        return (relativePosition * displayTasks.length).round().clamp(0, displayTasks.length);
      }
      return displayTasks.length;
    }
    
    // Use DropPositionCalculator with actual positions
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    
    return DropPositionCalculator.calculateClosestCardIndex(
      dragOffset: dragOffset,
      cardGlobalPositions: cardPositions,
      columnScrollOffset: scrollOffset,
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
