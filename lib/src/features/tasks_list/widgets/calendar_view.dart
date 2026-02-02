import 'package:flutter/material.dart';

import '../../../common/utils/date_utils.dart';
import '../../board/models/task.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    required this.tasks,
    this.onTaskTap,
  });

  final List<Task> tasks;
  final ValueChanged<Task>? onTaskTap;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = AppDateUtils.startOfMonth(_focusedMonth);
    final startOfGrid = AppDateUtils.startOfWeek(firstOfMonth);
    final totalCells = 42;

    final grouped = <DateTime, List<Task>>{};
    for (final task in widget.tasks) {
      if (task.dueDate == null) continue;
      final key = AppDateUtils.normalizeDate(task.dueDate!);
      grouped.putIfAbsent(key, () => []).add(task);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 12),
        _buildWeekdayRow(theme),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final date = startOfGrid.add(Duration(days: index));
            final inMonth = date.month == _focusedMonth.month;
            final dayTasks = grouped[AppDateUtils.normalizeDate(date)] ?? [];
            return _buildDayCell(
              context,
              date: date,
              inMonth: inMonth,
              tasks: dayTasks,
            );
          },
        ),
        const SizedBox(height: 16),
        _buildNoDueDateSection(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Text(
          AppDateUtils.formatMonthYear(_focusedMonth),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Previous month',
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
                1,
              );
            });
          },
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
                1,
              );
            });
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildWeekdayRow(ThemeData theme) {
    final labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required DateTime date,
    required bool inMonth,
    required List<Task> tasks,
  }) {
    final theme = Theme.of(context);
    final maxVisible = 3;
    final visibleTasks = tasks.take(maxVisible).toList();
    final remaining = tasks.length - visibleTasks.length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppDateUtils.formatDayNumber(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: inMonth
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...visibleTasks.map((task) => _buildTaskChip(theme, task)),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$remaining more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskChip(ThemeData theme, Task task) {
    final dueDate = task.dueDate;
    final timeLabel = (dueDate != null && AppDateUtils.hasTimeComponent(dueDate))
        ? AppDateUtils.formatTime(dueDate)
        : null;

    return GestureDetector(
      onTap: widget.onTaskTap != null ? () => widget.onTaskTap!(task) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: task.status.color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: task.status.color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            if (timeLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  timeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDueDateSection(ThemeData theme) {
    final noDueDateTasks = widget.tasks.where((t) => t.dueDate == null).toList();
    if (noDueDateTasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No due date',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: noDueDateTasks
              .map(
                (task) => Chip(
                  label: Text(task.title),
                  backgroundColor: task.status.color.withOpacity(0.2),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
