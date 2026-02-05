import 'package:flutter/material.dart';
import '../../theme/animation_timings.dart';

/// StatusMomentum: Encodes task status direction through animated chevron and drag shimmer.
///
/// Shows users the direction they can move a task without explicit buttons.
/// - Hover: Chevron rotates to indicate valid status moves
/// - Drag: Shimmer flows in drag direction (momentum visualization)
/// - Drop valid: Outward pulse + color shift to new status
/// - Drop invalid: Shimmer reverses and shrinks (rejection feedback)
///
/// Example:
/// ```dart
/// StatusMomentum(
///   status: task.status,
///   isDragging: isDragging,
///   child: TaskCard(...),
/// )
/// ```

class StatusMomentum extends StatefulWidget {
  const StatusMomentum({
    super.key,
    required this.status,
    required this.child,
    this.isDragging = false,
    this.onStatusChange,
  });

  final dynamic status; // TaskStatus enum
  final Widget child;
  final bool isDragging;
  final VoidCallback? onStatusChange;

  @override
  State<StatusMomentum> createState() => _StatusMomentumState();
}

class _StatusMomentumState extends State<StatusMomentum>
    with TickerProviderStateMixin {
  late AnimationController _chevronController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  bool _isHovered = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.statusChevronRotateMs,
        ),
      ),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.dragShimmerDurationMs,
        ),
      ),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.statusPulseMs,
        ),
      ),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(StatusMomentum oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDragging && !_isDragging) {
      _shimmerController.repeat();
    } else if (!widget.isDragging && _isDragging) {
      _shimmerController.stop();
    }
    _isDragging = widget.isDragging;
  }

  @override
  void dispose() {
    _chevronController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _chevronController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _chevronController.reverse();
      },
      child: Stack(
        children: [
          // Shimmer overlay (visible during drag)
          if (widget.isDragging) _buildShimmerOverlay(),

          // Main child
          widget.child,

          // Chevron indicator (visible on hover)
          if (_isHovered && !widget.isDragging) _buildChevronIndicator(),

          // Pulse effect (triggered on valid drop)
          _buildPulseEffect(),
        ],
      ),
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        // Shimmer moves left-to-right with trailing effect
        final offset = (_shimmerController.value * 60.0) -
            (_shimmerController.value * 60.0).floor().toDouble();

        return Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(offset - 0.3, 0),
                  end: Alignment(offset, 0),
                  colors: [
                    Colors.transparent,
                    Colors.blue.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Container(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChevronIndicator() {
    return Positioned(
      top: 12,
      right: 12,
      child: RotationTransition(
        turns: Tween<double>(begin: 0.0, end: 0.25).animate(
          CurvedAnimation(parent: _chevronController, curve: Curves.easeOutCubic),
        ),
        child: Icon(
          Icons.chevron_right,
          color: Colors.blue.withOpacity(0.6),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildPulseEffect() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Pulse: 1.0 → 1.15 → 1.0 using TweenSequence
        final tween = TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.15),
            weight: 50,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.15, end: 1.0),
            weight: 50,
          ),
        ]);

        final scale = tween.evaluate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

        return Transform.scale(
          scale: scale,
          child: Container(), // Invisible, but provides scaling transform
        );
      },
    );
  }
}
