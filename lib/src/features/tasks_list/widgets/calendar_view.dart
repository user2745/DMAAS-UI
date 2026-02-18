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
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.85,
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
    final isToday = AppDateUtils.normalizeDate(date) ==
        AppDateUtils.normalizeDate(DateTime.now());
    final hasTasks = tasks.isNotEmpty;

    return GestureDetector(
      onTap: hasTasks
          ? () => _showDaySheet(context, date, tasks)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isToday
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.onSurface.withOpacity(0.10),
            width: isToday ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Text(
              AppDateUtils.formatDayNumber(date),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: isToday
                    ? theme.colorScheme.primary
                    : inMonth
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (hasTasks) ...[
              const SizedBox(height: 4),
              // Colored dots — up to 3
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...tasks.take(3).map(
                    (t) => Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: t.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (tasks.length > 3)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDaySheet(BuildContext context, DateTime date, List<Task> tasks) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppDateUtils.formatMonthYear(date).contains(date.year.toString())
                      ? '${_weekdayLabel(date.weekday)}, ${AppDateUtils.formatDayNumber(date)} ${_monthLabel(date.month)}'
                      : AppDateUtils.formatMonthYear(date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...tasks.map(
                  (task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: task.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: task.description != null && task.description!.isNotEmpty
                        ? Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                    trailing: Chip(
                      label: Text(
                        task.status.label,
                        style: TextStyle(
                          color: task.status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: task.status.color.withOpacity(0.12),
                      side: BorderSide(color: task.status.color.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onTaskTap != null) widget.onTaskTap!(task);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _weekdayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String _monthLabel(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
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
