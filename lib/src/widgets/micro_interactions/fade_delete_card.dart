import 'package:flutter/material.dart';
import '../../theme/animation_timings.dart';

/// FadeDeleteCard: Destructive action with 5-second undo window.
///
/// When delete is triggered:
/// 1. Card fades out + compresses vertically over 5 seconds
/// 2. Border turns red (visual warning)
/// 3. Shadow fades as opacity decreases
/// 4. Other cards slide up to fill space
/// 5. Hovering reveals undo button in center
/// 6. Click undo reverses all animations
/// 7. Timer completes → card pulses red then removes
///
/// Example:
/// ```dart
/// FadeDeleteCard(
///   onDelete: () => deleteTask(task.id),
///   onUndo: () => restoreTask(task.id),
///   child: TaskCard(...),
/// )
/// ```

class FadeDeleteCard extends StatefulWidget {
  const FadeDeleteCard({
    super.key,
    required this.child,
    required this.onDelete,
    this.onUndo,
    this.borderRadius = 12,
  });

  final Widget child;
  final VoidCallback onDelete; // Triggered when delete completes
  final VoidCallback? onUndo;
  final double borderRadius;

  @override
  State<FadeDeleteCard> createState() => _FadeDeleteCardState();
}

class _FadeDeleteCardState extends State<FadeDeleteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _isDeleting = false;
  bool _isHoveredDuringFade = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AnimationTimings.deleteDuration(),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void triggerDelete() {
    setState(() => _isDeleting = true);
    _fadeController.forward().then((_) {
      if (mounted) {
        widget.onDelete();
      }
    });
  }

  void _triggerUndo() {
    _fadeController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    });
    widget.onUndo?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeleting) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        // Fade: 1.0 → 0.0
        final opacity = 1.0 - _fadeController.value;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHoveredDuringFade = true),
          onExit: (_) => setState(() => _isHoveredDuringFade = false),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fading card
              SizeTransition(
                sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(parent: _fadeController, curve: Curves.easeInCubic),
                ),
                child: Opacity(
                  opacity: opacity,
                  child: _buildFadingCard(),
                ),
              ),

              // Undo button (appears on hover during fade)
              if (_isHoveredDuringFade && _fadeController.value < 0.95)
                FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.1, 0.3),
                    ),
                  ),
                  child: _buildUndoButton(),
                ),

              // Timer toast (shows remaining undo time)
              Positioned(
                bottom: 16,
                right: 16,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.8, 1.0),
                    ),
                  ),
                  child: _buildTimerToast(),
                ),
              ),

              // Final pulse effect (red flash before removal)
              if (_fadeController.value > 0.99) _buildFinalPulse(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFadingCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Color.lerp(
            Colors.transparent,
            Colors.red,
            _fadeController.value,
          )!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1 * (1.0 - _fadeController.value)),
            blurRadius: 8 * (1.0 - _fadeController.value),
            offset: Offset(0, 2 * (1.0 - _fadeController.value)),
          ),
        ],
      ),
      child: widget.child,
    );
  }

  Widget _buildUndoButton() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _triggerUndo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.undo,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Undo Delete',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerToast() {
    final theme = Theme.of(context);
    final remainingSeconds =
        (AnimationTimings.apply(AnimationTimings.deleteFadeOutMs) *
                (1.0 - _fadeController.value)) ~/
            1000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.undo,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            '${remainingSeconds}s',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPulse() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        // Pulse: 1.0 → 1.08 → 1.0 at the very end
        final pulseProgress = (_fadeController.value - 0.99) / 0.01; // 0.0 to 1.0

        if (pulseProgress < 0) return const SizedBox.shrink();

        final tween = TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.08),
            weight: 50,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.08, end: 1.0),
            weight: 50,
          ),
        ]);

        final scale = tween.evaluate(AlwaysStoppedAnimation(pulseProgress));

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: Colors.red.withOpacity(pulseProgress),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
