import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../board/cubit/task_board_cubit.dart';
import '../board/models/task.dart';

class TodayTasksPage extends StatelessWidget {
  const TodayTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBoardCubit, TaskBoardState>(
      builder: (context, state) {
        // Filter tasks that have a due date and are today or in the future
        final today = DateTime.now();
        final filteredTasks = state.tasks.where((task) {
          if (task.dueDate == null) return false;
          final dueDate = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          final todayDate = DateTime(today.year, today.month, today.day);
          return dueDate.isAtSameMomentAs(todayDate) || dueDate.isAfter(todayDate);
        }).toList();

        // Group tasks by due date
        final groupedByDate = <DateTime, List<Task>>{};
        for (final task in filteredTasks) {
          final date = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          groupedByDate.putIfAbsent(date, () => []).add(task);
        }

        // Sort dates
        final sortedDates = groupedByDate.keys.toList()..sort();

        if (sortedDates.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No Upcoming Tasks",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have no tasks scheduled for today and beyond.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Tasks",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ...sortedDates.map((date) {
                final tasksForDate = groupedByDate[date]!;
                final isToday = DateTime(
                  date.year,
                  date.month,
                  date.day,
                ).isAtSameMomentAs(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        isToday
                            ? 'Today'
                            : _formatDate(date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    // Tasks for this day
                    ...tasksForDate.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _TaskCard(task: task),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title and status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: task.status.color.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.status.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              task.description ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
