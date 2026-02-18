import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/utils/date_utils.dart';
import '../../board/models/task.dart';

class RoadmapView extends StatefulWidget {
  const RoadmapView({
    super.key,
    required this.tasks,
    this.onAddTaskAtDate,
    this.onTaskTap,
  });

  final List<Task> tasks;
  final ValueChanged<DateTime>? onAddTaskAtDate;
  final ValueChanged<Task>? onTaskTap;

  @override
  State<RoadmapView> createState() => _RoadmapViewState();
}

class _RoadmapViewState extends State<RoadmapView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  RoadmapZoomLevel _zoomLevel = RoadmapZoomLevel.month;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = _getEffectiveRangeStart(widget.tasks, _zoomLevel);
    _rangeEnd = _getEffectiveRangeEnd(widget.tasks, _zoomLevel);
    _scrollController.addListener(_handleInfiniteScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleInfiniteScroll);
    _scrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet',
          style: TextStyle(color: Color(0xFF8B949E)),
        ),
      );
    }

    final start = _rangeStart;
    final end = _rangeEnd;
    final totalDays = max(1, AppDateUtils.daysBetween(start, end) + 1);

    final dayWidth = _zoomLevel.dayWidth;
    const rowHeight = 56.0;
    const titleColumnWidth = 200.0;
    const headerHeight = 56.0;

    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls row (zoom + today)
        _buildControls(context),
        // Gantt chart — fills remaining height
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frozen title column
              SizedBox(
                width: titleColumnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header cell
                    Container(
                      height: headerHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Task',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    // Task title rows — vertically scrollable, synced
                    Expanded(
                      child: ListView.builder(
                        controller: _verticalScrollController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: sortedTasks.length + 1,
                        itemBuilder: (context, index) {
                          if (index == sortedTasks.length) {
                            return SizedBox(
                              height: rowHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: widget.onAddTaskAtDate != null
                                      ? () => widget.onAddTaskAtDate!(
                                            DateTime.now()
                                                .add(const Duration(days: 7)),
                                          )
                                      : null,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add task'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                              ),
                            );
                          }
                          final task = sortedTasks[index];
                          return Container(
                            height: rowHeight,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: const Color(0xFF21262D),
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: task.status.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 13, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, color: Color(0xFF21262D)),
              // Chart pane
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final timelineWidth = max(
                      totalDays * dayWidth,
                      constraints.maxWidth + (dayWidth * 30),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sticky date header
                        SizedBox(
                          height: headerHeight,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: timelineWidth,
                              child: Column(
                                children: [
                                  _buildMonthRow(context, start, end, dayWidth),
                                  _buildDayRow(context, start, totalDays, dayWidth),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Scrollable chart body
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              // sync vertical scroll to title column
                              if (n is ScrollUpdateNotification &&
                                  n.metrics.axis == Axis.vertical) {
                                if (_verticalScrollController.hasClients) {
                                  _verticalScrollController.jumpTo(
                                      n.metrics.pixels);
                                }
                              }
                              return false;
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _scrollController,
                              child: SizedBox(
                                width: timelineWidth,
                                child: ListView.builder(
                                  itemCount: sortedTasks.length,
                                  itemExtent: rowHeight,
                                  itemBuilder: (context, index) {
                                    final task = sortedTasks[index];
                                    return _buildTaskRow(
                                      context,
                                      task: task,
                                      rangeStart: start,
                                      dayWidth: dayWidth,
                                      rowHeight: rowHeight,
                                      totalWidth: timelineWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _scrollToToday() {
    if (!mounted || !_scrollController.hasClients) return;
    final tasks = widget.tasks;
    if (tasks.isEmpty) return;
    final start = _rangeStart;
    final today = AppDateUtils.normalizeDate(DateTime.now());
    final offsetDays = AppDateUtils.daysBetween(start, today);
    final target = (offsetDays * _zoomLevel.dayWidth) - 120;
    final clamped = target.clamp(0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(clamped.toDouble());
  }

  void _handleInfiniteScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const edgeThreshold = 200.0;
    if (position.pixels <= edgeThreshold) {
      _extendRange(before: true);
    } else if (position.pixels >= position.maxScrollExtent - edgeThreshold) {
      _extendRange(before: false);
    }
  }

  void _extendRange({required bool before}) {
    final bufferDays = _zoomBufferDays(_zoomLevel);
    if (before) {
      final newStart = _rangeStart.subtract(Duration(days: bufferDays));
      if (newStart == _rangeStart) return;
      setState(() {
        _rangeStart = newStart;
      });
      final shift = bufferDays * _zoomLevel.dayWidth;
      _scrollController.jumpTo(
        _scrollController.offset + shift,
      );
    } else {
      final newEnd = _rangeEnd.add(Duration(days: bufferDays));
      if (newEnd == _rangeEnd) return;
      setState(() {
        _rangeEnd = newEnd;
      });
    }
  }

  DateTime _getRangeStart(List<Task> tasks) {
    return tasks
        .map((t) => AppDateUtils.normalizeDate(t.createdAt))
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime _getRangeEnd(List<Task> tasks) {
    return tasks
        .map((t) => AppDateUtils.normalizeDate(t.dueDate ?? t.createdAt))
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  DateTime _getEffectiveRangeStart(
    List<Task> tasks,
    RoadmapZoomLevel zoomLevel,
  ) {
    final baseStart = _getRangeStart(tasks);
    final buffer = _zoomBufferDays(zoomLevel);
    final today = AppDateUtils.normalizeDate(DateTime.now());
    final paddedToday = today.subtract(Duration(days: buffer));
    return baseStart.isBefore(paddedToday) ? baseStart : paddedToday;
  }

  DateTime _getEffectiveRangeEnd(
    List<Task> tasks,
    RoadmapZoomLevel zoomLevel,
  ) {
    final baseEnd = _getRangeEnd(tasks);
    final buffer = _zoomBufferDays(zoomLevel);
    final today = AppDateUtils.normalizeDate(DateTime.now());
    final paddedToday = today.add(Duration(days: buffer));
    return baseEnd.isAfter(paddedToday) ? baseEnd : paddedToday;
  }

  int _zoomBufferDays(RoadmapZoomLevel zoomLevel) {
    switch (zoomLevel) {
      case RoadmapZoomLevel.month:
        return 30;
      case RoadmapZoomLevel.quarter:
        return 90;
      case RoadmapZoomLevel.year:
        return 180;
    }
  }

  Widget _buildMonthRow(
    BuildContext context,
    DateTime start,
    DateTime end,
    double dayWidth,
  ) {
    final months = <Widget>[];
    var cursor = DateTime(start.year, start.month, 1);
    while (cursor.isBefore(end) || AppDateUtils.isSameDay(cursor, end)) {
      final monthStart = cursor;
      final daysInMonth = AppDateUtils.daysInMonth(monthStart);
      final monthEnd = DateTime(monthStart.year, monthStart.month, daysInMonth);
      final visibleStart = monthStart.isBefore(start) ? start : monthStart;
      final visibleEnd = monthEnd.isAfter(end) ? end : monthEnd;
      final visibleDays =
          AppDateUtils.daysBetween(visibleStart, visibleEnd) + 1;
      months.add(
        SizedBox(
          width: visibleDays * dayWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppDateUtils.formatShortMonth(monthStart),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      );
      cursor = DateTime(monthStart.year, monthStart.month + 1, 1);
    }

    return SizedBox(
      height: 22,
      child: Row(children: months),
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    DateTime start,
    int totalDays,
    double dayWidth,
  ) {
    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(totalDays, (index) {
          final date = start.add(Duration(days: index));
          final isFirstOfMonth = date.day == 1;
          return SizedBox(
            width: dayWidth,
            child: Center(
              child: Text(
                _zoomLevel == RoadmapZoomLevel.year && !isFirstOfMonth
                    ? ''
                    : AppDateUtils.formatDayNumber(date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color:
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Zoom selector left-aligned
          DropdownButton<RoadmapZoomLevel>(
            value: _zoomLevel,
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _zoomLevel = value;
                _rangeStart = _getEffectiveRangeStart(widget.tasks, value);
                _rangeEnd = _getEffectiveRangeEnd(widget.tasks, value);
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToToday();
              });
            },
            items: RoadmapZoomLevel.values
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(level.label,
                        style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _scrollToToday,
            icon: const Icon(Icons.my_location, size: 16),
            label: const Text('Today'),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ],
      ),
    );
  }
  Widget _buildTaskRow(
    BuildContext context, {
    required Task task,
    required DateTime rangeStart,
    required double dayWidth,
    required double rowHeight,
    required double totalWidth,
  }) {
    final start = AppDateUtils.normalizeDate(task.createdAt);
    final end = AppDateUtils.normalizeDate(task.dueDate ?? task.createdAt);
    final offsetDays = AppDateUtils.daysBetween(rangeStart, start);
    final durationDays = max(1, AppDateUtils.daysBetween(start, end) + 1);
    final left = offsetDays * dayWidth;
    final barWidth = max(durationDays * dayWidth, 40.0);
    final barHeight = rowHeight - 16;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        final localX = details.localPosition.dx;
        if (localX >= left && localX <= left + barWidth) {
          widget.onTaskTap?.call(task);
        } else if (widget.onAddTaskAtDate != null) {
          final tappedDay = (localX / dayWidth).floor();
          final date = rangeStart.add(Duration(days: max(0, tappedDay)));
          widget.onAddTaskAtDate?.call(date);
        }
      },
      child: Container(
        width: totalWidth,
        height: rowHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: const Color(0xFF21262D), width: 1),
          ),
        ),
        child: Stack(
          children: [
            // Today line overlay (drawn per-row so it appears over grid)
            Positioned(
              left: AppDateUtils.daysBetween(
                          rangeStart,
                          AppDateUtils.normalizeDate(DateTime.now())) *
                      dayWidth,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: const Color(0x55FF4D4F)),
            ),
            // Task bar
            Positioned(
              left: left,
              top: 8,
              child: Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: task.status.color.withAlpha(70),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: task.status.color.withAlpha(180), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: task.status.color,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum RoadmapZoomLevel { month, quarter, year }

extension RoadmapZoomLevelX on RoadmapZoomLevel {
  String get label {
    switch (this) {
      case RoadmapZoomLevel.month:
        return 'Month';
      case RoadmapZoomLevel.quarter:
        return 'Quarter';
      case RoadmapZoomLevel.year:
        return 'Year';
    }
  }

  double get dayWidth {
    switch (this) {
      case RoadmapZoomLevel.month:
        return 26.0;
      case RoadmapZoomLevel.quarter:
        return 14.0;
      case RoadmapZoomLevel.year:
        return 6.0;
    }
  }
}
