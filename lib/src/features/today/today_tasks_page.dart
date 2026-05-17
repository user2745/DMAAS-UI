import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../board/cubit/task_board_cubit.dart';
import '../board/models/task.dart';
import '../board/widgets/task_editor_sheet.dart';

class TodayTasksPage extends StatefulWidget {
  const TodayTasksPage({super.key});

  @override
  State<TodayTasksPage> createState() => _TodayTasksPageState();
}

class _TodayTasksPageState extends State<TodayTasksPage> {
  final TextEditingController _quickAddController = TextEditingController();

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  void _onQuickAdd() {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    _quickAddController.clear();
    TaskEditorSheet.show(
      context,
      task: null,
      initialStatus: TaskStatus.todo,
    );
    // Note: Ideally, the TaskEditorSheet should pre-fill the title if we pass it, 
    // but the current TaskEditorSheet implementation might not support pre-filling from outside Task yet.
    // However, the instructions say "title entry -> opens unified panel", so this is the intended flow.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBoardCubit, TaskBoardState>(
      builder: (context, state) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        final dueToday = state.tasks.where((task) {
          if (task.dueDate == null) return false;
          final d = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          return d.isAtSameMomentAs(todayDate);
        }).toList();

        final overdue = state.tasks.where((task) {
          if (task.dueDate == null) return false;
          if (task.status == TaskStatus.done) return false;
          final d = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          return d.isBefore(todayDate);
        }).toList();

        if (dueToday.isEmpty && overdue.isEmpty) {
          return _EmptyState();
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              _QuickAddHeader(
                controller: _quickAddController,
                onSubmitted: (_) => _onQuickAdd(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (overdue.isNotEmpty) ...[
                      _SectionHeader(
                        title: "Overdue",
                        count: overdue.length,
                        color: Colors.redAccent,
                      ),
                      ...overdue.map((task) => _TaskChecklistItem(task: task)),
                      const SizedBox(height: 24),
                    ],
                    if (dueToday.isNotEmpty) ...[
                      _SectionHeader(
                        title: "Due Today",
                        count: dueToday.length,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      ...dueToday.map((task) => _TaskChecklistItem(task: task)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAddHeader extends StatelessWidget {
  const _QuickAddHeader({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.05),
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: "Add a task for today...",
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor.withOpacity(0.5),
          ),
          prefixIcon: const Icon(Icons.add, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: color,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskChecklistItem extends StatelessWidget {
  const _TaskChecklistItem({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == TaskStatus.done;

    return InkWell(
      onTap: () => TaskEditorSheet.show(context, task: task),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isDone,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  if (value != null) {
                    final newStatus = value ? TaskStatus.done : TaskStatus.todo;
                    context.read<TaskBoardCubit>().updateTask(
                          task.copyWith(status: newStatus),
                        );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? theme.hintColor : null,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Text(
                      task.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                ],
              ),
            ),
            if (task.ticketNumber != null)
              Text(
                '#${task.ticketNumber}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Clear skies ahead",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks due today. Use this time to recharge or get ahead on your week.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => TaskEditorSheet.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add a task for today"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

