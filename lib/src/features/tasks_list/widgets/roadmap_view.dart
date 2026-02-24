import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/utils/date_utils.dart';
import '../../board/models/task.dart';
import '../../preferences/cubit/preferences_cubit.dart';
import '../cubit/tasks_list_cubit.dart';
import '../models/field.dart';
import '../utils/workback_utils.dart';

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
  late RoadmapZoomLevel _zoomLevel;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  // ───────────────────────────── Lifecycle ──────────────────────────────────

  @override
  void initState() {
    super.initState();
    final prefState = context.read<PreferencesCubit>().state;
    _zoomLevel = _zoomFromString(prefState.roadmapZoomLevel);
    _rangeStart = _getEffectiveRangeStart(widget.tasks, _zoomLevel);
    _rangeEnd = _getEffectiveRangeEnd(widget.tasks, _zoomLevel);
    _scrollController.addListener(_handleInfiniteScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleInfiniteScroll);
    _scrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksListCubit, TasksListState>(
      buildWhen: (prev, curr) =>
          prev.groupedRoadmapTasks != curr.groupedRoadmapTasks ||
          prev.scheduleMode != curr.scheduleMode ||
          prev.groupByFieldId != curr.groupByFieldId ||
          prev.fields != curr.fields,
      builder: (context, state) {
        final grouped = state.groupedRoadmapTasks;
        final allTasks = grouped.values.expand((t) => t).toList();

        if (allTasks.isEmpty) {
          return const Center(
            child: Text('No tasks yet',
                style: TextStyle(color: Color(0xFF8B949E))),
          );
        }

        final start = _rangeStart;
        final end = _rangeEnd;
        final totalDays = max(1, AppDateUtils.daysBetween(start, end) + 1);
        final dayWidth = _zoomLevel.dayWidth;
        const rowHeight = 56.0;
        const groupHeaderHeight = 36.0;
        const titleColumnWidth = 200.0;
        const headerHeight = 56.0;

        final rows = _buildRows(grouped, state.scheduleMode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context, state),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Frozen title column ────────────────────────────────
                  SizedBox(
                    width: titleColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: headerHeight,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Task',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _verticalScrollController,
                            physics: const ClampingScrollPhysics(),
                            itemCount: rows.length + 1,
                            itemBuilder: (context, index) {
                              if (index == rows.length) {
                                return SizedBox(
                                  height: rowHeight,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: widget.onAddTaskAtDate != null
                                          ? () => widget.onAddTaskAtDate!(
                                              DateTime.now()
                                                  .add(const Duration(days: 7)))
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
                              final row = rows[index];
                              if (row is _GroupHeaderRow) {
                                return _buildTitleGroupHeader(
                                    context, row, groupHeaderHeight, state);
                              }
                              return _buildTitleCell(
                                  context, (row as _TaskRow).task, rowHeight);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF21262D)),
                  // ── Chart pane ────────────────────────────────────────
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
                            SizedBox(
                              height: headerHeight,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  width: timelineWidth,
                                  child: Column(children: [
                                    _buildMonthRow(
                                        context, start, end, dayWidth),
                                    _buildDayRow(
                                        context, start, totalDays, dayWidth),
                                  ]),
                                ),
                              ),
                            ),
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (n) {
                                  if (n is ScrollUpdateNotification &&
                                      n.metrics.axis == Axis.vertical &&
                                      _verticalScrollController.hasClients) {
                                    _verticalScrollController
                                        .jumpTo(n.metrics.pixels);
                                  }
                                  return false;
                                },
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _scrollController,
                                  child: SizedBox(
                                    width: timelineWidth,
                                    child: ListView.builder(
                                      itemCount: rows.length,
                                      itemBuilder: (context, index) {
                                        final row = rows[index];
                                        if (row is _GroupHeaderRow) {
                                          return _buildChartGroupHeader(
                                              context,
                                              groupHeaderHeight,
                                              timelineWidth);
                                        }
                                        final tr = row as _TaskRow;
                                        return _buildTaskRow(
                                          context,
                                          task: tr.task,
                                          barDates: tr.barDates,
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
      },
    );
  }

  // ──────────────────── Row model ────────────────────────────────────────────

  List<_RoadmapRow> _buildRows(
    Map<String, List<Task>> grouped,
    ScheduleMode mode,
  ) {
    final rows = <_RoadmapRow>[];
    final hasGroups = grouped.keys.any((k) => k.isNotEmpty);
    for (final entry in grouped.entries) {
      if (hasGroups && entry.key.isNotEmpty) {
        rows.add(_GroupHeaderRow(label: entry.key, count: entry.value.length));
      }
      for (final task in entry.value) {
        rows.add(_TaskRow(task: task, barDates: resolveBarDates(task, mode)));
      }
    }
    return rows;
  }

  // ──────────────────── Toolbar ──────────────────────────────────────────────

  Widget _buildToolbar(BuildContext context, TasksListState state) {
    final theme = Theme.of(context);
    final cubit = context.read<TasksListCubit>();
    final prefsCubit = context.read<PreferencesCubit>();

    final groupOptions = <_GroupOption>[
      const _GroupOption(value: null, label: 'None'),
      const _GroupOption(value: '__status__', label: 'Status'),
      ...state.fields
          .where((f) =>
              f.type == FieldType.singleSelect || f.type == FieldType.text)
          .map((f) => _GroupOption(value: f.id, label: f.name)),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SegmentedButton<ScheduleMode>(
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: theme.textTheme.labelSmall,
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                value: ScheduleMode.gantt,
                label: Text('Gantt'),
                icon: Icon(Icons.bar_chart, size: 14),
              ),
              ButtonSegment(
                value: ScheduleMode.workback,
                label: Text('Workback'),
                icon: Icon(Icons.replay, size: 14),
              ),
            ],
            selected: {state.scheduleMode},
            onSelectionChanged: (s) =>
                cubit.setScheduleMode(s.first, preferencesCubit: prefsCubit),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: state.groupByFieldId,
              isDense: true,
              hint: Text('Group: None', style: theme.textTheme.labelSmall),
              items: groupOptions
                  .map((opt) => DropdownMenuItem<String?>(
                        value: opt.value,
                        child: Text('Group: ${opt.label}',
                            style: theme.textTheme.labelSmall),
                      ))
                  .toList(),
              onChanged: (value) =>
                  cubit.setGroupBy(value, preferencesCubit: prefsCubit),
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<RoadmapZoomLevel>(
              value: _zoomLevel,
              isDense: true,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _zoomLevel = value;
                  _rangeStart = _getEffectiveRangeStart(widget.tasks, value);
                  _rangeEnd = _getEffectiveRangeEnd(widget.tasks, value);
                });
                prefsCubit.setRoadmapZoomLevel(value.name);
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToToday());
              },
              items: RoadmapZoomLevel.values
                  .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(l.label,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
            ),
          ),
          TextButton.icon(
            onPressed: _scrollToToday,
            icon: const Icon(Icons.my_location, size: 16),
            label: const Text('Today'),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ],
      ),
    );
  }

  // ──────────────────── Title column cells ───────────────────────────────────

  Widget _buildTitleGroupHeader(
    BuildContext context,
    _GroupHeaderRow row,
    double height,
    TasksListState state,
  ) {
    final theme = Theme.of(context);
    Color groupColor = theme.colorScheme.primary;
    if (state.groupByFieldId == '__status__') {
      for (final s in TaskStatus.values) {
        if (s.label == row.label) {
          groupColor = s.color;
          break;
        }
      }
    } else if (state.groupByFieldId != null) {
      final field = state.getFieldById(state.groupByFieldId!);
      if (field != null) groupColor = field.color;
    }
    return Container(
      height: height,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: groupColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: groupColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: groupColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${row.count}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: groupColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCell(BuildContext context, Task task, double rowHeight) {
    return Container(
      height: rowHeight,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFF21262D), width: 1)),
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
  }

  // ──────────────────── Chart rows ───────────────────────────────────────────

  Widget _buildChartGroupHeader(
    BuildContext context,
    double height,
    double totalWidth,
  ) {
    return Container(
      width: totalWidth,
      height: height,
      color: Theme.of(context).colorScheme.surface,
      child: const Divider(height: 1, color: Color(0xFF21262D)),
    );
  }

  Widget _buildTaskRow(
    BuildContext context, {
    required Task task,
    required ({DateTime start, DateTime end}) barDates,
    required DateTime rangeStart,
    required double dayWidth,
    required double rowHeight,
    required double totalWidth,
  }) {
    final barStart = barDates.start;
    final barEnd = barDates.end;
    final isMilestone = barStart == barEnd;
    final offsetDays = AppDateUtils.daysBetween(rangeStart, barStart);
    final durationDays = max(1, AppDateUtils.daysBetween(barStart, barEnd) + 1);
    final left = offsetDays * dayWidth;
    final barWidth = isMilestone ? 0.0 : max(durationDays * dayWidth, 40.0);
    final barHeight = rowHeight - 16;
    final color = task.status.color;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        final x = details.localPosition.dx;
        final hitL = isMilestone ? left - 12 : left;
        final hitR = isMilestone ? left + 12 : left + barWidth;
        if (x >= hitL && x <= hitR) {
          widget.onTaskTap?.call(task);
        } else if (widget.onAddTaskAtDate != null) {
          final tappedDay = (x / dayWidth).floor();
          widget.onAddTaskAtDate
              ?.call(rangeStart.add(Duration(days: max(0, tappedDay))));
        }
      },
      child: Container(
        width: totalWidth,
        height: rowHeight,
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0xFF21262D), width: 1)),
        ),
        child: Stack(
          children: [
            // Today line
            Positioned(
              left: AppDateUtils.daysBetween(rangeStart,
                      AppDateUtils.normalizeDate(DateTime.now())) *
                  dayWidth,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: const Color(0x55FF4D4F)),
            ),
            if (isMilestone)
              // Milestone diamond ◆
              Positioned(
                left: left - 10,
                top: rowHeight / 2 - 10,
                child: Transform.rotate(
                  angle: 0.785398, // 45°
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color.withAlpha(80),
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              )
            else
              // Standard bar
              Positioned(
                left: left,
                top: 8,
                child: Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color.withAlpha(70),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: color.withAlpha(180), width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  child: barWidth >= 60
                      ? Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: color,
                              ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── Date header rows ─────────────────────────────────────

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
      final visibleDays = AppDateUtils.daysBetween(visibleStart, visibleEnd) + 1;
      months.add(SizedBox(
        width: visibleDays * dayWidth,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppDateUtils.formatShortMonth(monthStart),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ));
      cursor = DateTime(monthStart.year, monthStart.month + 1, 1);
    }
    return SizedBox(height: 22, child: Row(children: months));
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
          return SizedBox(
            width: dayWidth,
            child: Center(
              child: Text(
                _zoomLevel == RoadmapZoomLevel.year && date.day != 1
                    ? ''
                    : AppDateUtils.formatDayNumber(date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────── Scroll helpers ───────────────────────────────────────

  void _scrollToToday() {
    if (!mounted || !_scrollController.hasClients) return;
    final today = AppDateUtils.normalizeDate(DateTime.now());
    final offsetDays = AppDateUtils.daysBetween(_rangeStart, today);
    final target = offsetDays * _zoomLevel.dayWidth - 120;
    _scrollController.jumpTo(
        target.clamp(0, _scrollController.position.maxScrollExtent));
  }

  void _handleInfiniteScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    const edge = 200.0;
    if (pos.pixels <= edge) {
      _extendRange(before: true);
    } else if (pos.pixels >= pos.maxScrollExtent - edge) {
      _extendRange(before: false);
    }
  }

  void _extendRange({required bool before}) {
    final buf = _zoomBufferDays(_zoomLevel);
    if (before) {
      final newStart = _rangeStart.subtract(Duration(days: buf));
      if (newStart == _rangeStart) return;
      setState(() => _rangeStart = newStart);
      _scrollController
          .jumpTo(_scrollController.offset + buf * _zoomLevel.dayWidth);
    } else {
      final newEnd = _rangeEnd.add(Duration(days: buf));
      if (newEnd == _rangeEnd) return;
      setState(() => _rangeEnd = newEnd);
    }
  }

  // ──────────────────── Range helpers ────────────────────────────────────────

  DateTime _getEffectiveRangeStart(List<Task> tasks, RoadmapZoomLevel zoom) {
    final mode = _currentMode();
    final buf = _zoomBufferDays(zoom);
    final paddedToday =
        AppDateUtils.normalizeDate(DateTime.now()).subtract(Duration(days: buf));
    if (tasks.isEmpty) return paddedToday;
    final base = tasks
        .map((t) => resolveBarDates(t, mode).start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return base.isBefore(paddedToday) ? base : paddedToday;
  }

  DateTime _getEffectiveRangeEnd(List<Task> tasks, RoadmapZoomLevel zoom) {
    final mode = _currentMode();
    final buf = _zoomBufferDays(zoom);
    final paddedToday =
        AppDateUtils.normalizeDate(DateTime.now()).add(Duration(days: buf));
    if (tasks.isEmpty) return paddedToday;
    final base = tasks
        .map((t) => resolveBarDates(t, mode).end)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return base.isAfter(paddedToday) ? base : paddedToday;
  }

  ScheduleMode _currentMode() {
    try {
      return context.read<TasksListCubit>().state.scheduleMode;
    } catch (_) {
      return ScheduleMode.gantt;
    }
  }

  int _zoomBufferDays(RoadmapZoomLevel zoom) {
    switch (zoom) {
      case RoadmapZoomLevel.month:
        return 30;
      case RoadmapZoomLevel.quarter:
        return 90;
      case RoadmapZoomLevel.year:
        return 180;
    }
  }

  static RoadmapZoomLevel _zoomFromString(String s) {
    switch (s) {
      case 'quarter':
        return RoadmapZoomLevel.quarter;
      case 'year':
        return RoadmapZoomLevel.year;
      default:
        return RoadmapZoomLevel.month;
    }
  }
}

// ──────────────────────── Row types ────────────────────────────────────────

abstract class _RoadmapRow {}

class _GroupHeaderRow extends _RoadmapRow {
  _GroupHeaderRow({required this.label, required this.count});
  final String label;
  final int count;
}

class _TaskRow extends _RoadmapRow {
  _TaskRow({required this.task, required this.barDates});
  final Task task;
  final ({DateTime start, DateTime end}) barDates;
}

// ──────────────────────── Group option ─────────────────────────────────────

class _GroupOption {
  const _GroupOption({required this.value, required this.label});
  final String? value;
  final String label;
}

// ──────────────────────── Enums ────────────────────────────────────────────

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
