import 'package:flutter/material.dart';
import '../../theme/animation_timings.dart';

/// UndoRedoWhisper: Floating badge showing reversibility through rotating arrow.
///
/// Appears after a change (title, description, field update) for 2 seconds.
/// The arrow oscillates to indicate "reversal is possible".
/// Hovering expands to show undo/redo buttons.
/// No text labels—pure visual communication.
///
/// Example:
/// ```dart
/// UndoRedoWhisper(
///   isVisible: _showUndoBadge,
///   onUndo: () => _undoLastChange(),
///   onRedo: () => _redoLastChange(),
/// )
/// ```

class UndoRedoWhisper extends StatefulWidget {
  const UndoRedoWhisper({
    super.key,
    required this.isVisible,
    required this.onUndo,
    required this.onRedo,
    this.onDismiss,
    this.position = const Offset(16, 16), // Bottom-right of modal/screen
  });

  final bool isVisible;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback? onDismiss;
  final Offset position; // Relative positioning

  @override
  State<UndoRedoWhisper> createState() => _UndoRedoWhisperState();
}

class _UndoRedoWhisperState extends State<UndoRedoWhisper>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _arrowController;
  late AnimationController _expandController;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.undoBadgeFadeInMs,
        ),
      ),
      vsync: this,
    );

    // Oscillating arrow (side-to-side motion)
    _arrowController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.undoArrowOscillateMs,
        ),
      ),
      vsync: this,
    )..repeat(reverse: true);

    // Expand animation (show undo/redo buttons)
    _expandController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.undoBadgeExpandMs,
        ),
      ),
      vsync: this,
    );

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(UndoRedoWhisper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _fadeController.forward();
      _startDismissTimer();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _fadeController.reverse();
    }
  }

  void _startDismissTimer() {
    Future.delayed(AnimationTimings.undoBadgeDuration, () {
      if (mounted && widget.isVisible) {
        _fadeController.reverse();
        widget.onDismiss?.call();
      }
    });
  }

  void _handleUndo() {
    _spinArrow();
    widget.onUndo();
  }

  void _handleRedo() {
    _spinArrow(reverse: true);
    widget.onRedo();
  }

  void _spinArrow({bool reverse = false}) {
    _arrowController.stop();
    _arrowController.forward(from: 0.0);

    Future.delayed(
      Duration(milliseconds: AnimationTimings.undoActionSpinMs),
      () {
        if (mounted) {
          _arrowController.repeat(reverse: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _arrowController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Positioned(
          bottom: widget.position.dy,
          right: widget.position.dx,
          child: Opacity(
            opacity: _fadeController.value,
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(_fadeController),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
                ),
                child: MouseRegion(
                  onEnter: (_) {
                    _expandController.forward();
                  },
                  onExit: (_) {
                    _expandController.reverse();
                  },
                  child: _buildBadge(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context) {
    final theme = Theme.of(context);

    if (_isExpanded) {
      return _buildExpandedButtons(theme);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.15),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: RotationTransition(
          turns: Tween<double>(begin: -AnimationTimings.undoArrowRotationDegrees / 360, end: AnimationTimings.undoArrowRotationDegrees / 360)
              .animate(
                CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
              ),
          child: Icon(
            Icons.undo,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo button
          IconButton(
            icon: Icon(
              Icons.undo,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            onPressed: _handleUndo,
            tooltip: 'Undo',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
          // Divider
          Container(
            width: 1,
            height: 20,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          // Redo button
          IconButton(
            icon: Icon(
              Icons.redo,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            onPressed: _handleRedo,
            tooltip: 'Redo',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}
