import '../../board/models/task.dart';
import '../cubit/tasks_list_cubit.dart' show ScheduleMode;
import '../../../common/utils/date_utils.dart';

/// Resolves the effective bar [start] and [end] dates for a task depending on
/// the current [ScheduleMode].
///
/// **Gantt mode** — left anchor is [Task.startDate] (falls back to
/// [Task.createdAt]), right anchor is [Task.dueDate] (falls back to start).
///
/// **Workback mode** — right anchor is [Task.dueDate] (falls back to
/// [Task.createdAt]), left anchor is end − [Task.estimatedDays] days (default 1).
({DateTime start, DateTime end}) resolveBarDates(
  Task task,
  ScheduleMode mode,
) {
  switch (mode) {
    case ScheduleMode.gantt:
      final start =
          AppDateUtils.normalizeDate(task.startDate ?? task.createdAt);
      final end = task.dueDate != null
          ? AppDateUtils.normalizeDate(task.dueDate!)
          : start;
      return (start: start, end: end.isBefore(start) ? start : end);

    case ScheduleMode.workback:
      final end = task.dueDate != null
          ? AppDateUtils.normalizeDate(task.dueDate!)
          : AppDateUtils.normalizeDate(task.createdAt);
      final duration = task.estimatedDays ?? 1;
      final start = end.subtract(Duration(days: duration - 1));
      return (start: start.isAfter(end) ? end : start, end: end);
  }
}
