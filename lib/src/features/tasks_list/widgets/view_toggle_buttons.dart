import 'package:flutter/material.dart';
import '../cubit/tasks_list_cubit.dart';

/// Design Language: Optimized View Transitions
/// Implements staggered entrance animations for view selection buttons.
/// Stagger: 50ms per item. Timing: 400ms EaseOutCubic.
class ViewToggleButtons extends StatefulWidget {
  const ViewToggleButtons({
    super.key,
    required this.currentViewMode,
    required this.onModeSelected,
  });

  final TaskViewMode currentViewMode;
  final ValueChanged<TaskViewMode> onModeSelected;

  @override
  State<ViewToggleButtons> createState() => _ViewToggleButtonsState();
}

class _ViewToggleButtonsState extends State<ViewToggleButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedButton(
          0,
          context,
          icon: Icons.calendar_today,
          label: 'Calendar',
          mode: TaskViewMode.calendar,
        ),
        const SizedBox(width: 8),
        _buildAnimatedButton(
          1,
          context,
          icon: Icons.timeline,
          label: 'Roadmap',
          mode: TaskViewMode.roadmap,
        ),
        const SizedBox(width: 8),
        _buildAnimatedButton(
          2,
          context,
          icon: Icons.list,
          label: 'List',
          mode: TaskViewMode.list,
        ),
      ],
    );
  }

  Widget _buildAnimatedButton(
    int index,
    BuildContext context, {
    required IconData icon,
    required String label,
    required TaskViewMode mode,
  }) {
    final start = index * 0.1;
    final end = start + 0.6;
    
    final fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(fadeAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: _buildButton(
          context,
          icon: icon,
          label: label,
          mode: mode,
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required TaskViewMode mode,
  }) {
    final selected = widget.currentViewMode == mode;
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
        onPressed: () => widget.onModeSelected(mode),
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
