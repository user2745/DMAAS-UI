import 'package:flutter/material.dart';

import '../cubit/tasks_list_cubit.dart';

class ViewToggleButtons extends StatelessWidget {
  const ViewToggleButtons({
    super.key,
    required this.currentViewMode,
    required this.onModeSelected,
  });

  final TaskViewMode currentViewMode;
  final ValueChanged<TaskViewMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          context,
          icon: Icons.calendar_today,
          label: 'Calendar',
          mode: TaskViewMode.calendar,
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          icon: Icons.timeline,
          label: 'Roadmap',
          mode: TaskViewMode.roadmap,
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          icon: Icons.list,
          label: 'List',
          mode: TaskViewMode.list,
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required TaskViewMode mode,
  }) {
    final selected = currentViewMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = selected ? colorScheme.primary : colorScheme.onSurface;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.25);
    final backgroundColor = selected
        ? colorScheme.primary.withOpacity(0.12)
        : colorScheme.surface;

    return Tooltip(
      message: label,
      child: TextButton.icon(
        onPressed: () => onModeSelected(mode),
        icon: Icon(icon, size: 16, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
        ),
      ),
    );
  }
}
