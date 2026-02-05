import 'package:flutter/material.dart';
import '../../theme/animation_timings.dart';

/// BreathingBorder: Encodes sync/loading state through border color animation.
///
/// Border color animates (idle → accent → idle) to show "in-flight" state.
/// Optional glow effect for critical operations.
/// Status circle indicator in corner shows: loading (spinning), synced (checkmark), error (pulsing).
///
/// Example:
/// ```dart
/// BreathingBorder(
///   isBreathing: _isSyncing,
///   borderColor: Colors.blue,
///   child: TaskCard(...),
///   statusIndicator: _getSyncStatus(), // 'loading', 'synced', 'error'
/// )
/// ```

class BreathingBorder extends StatefulWidget {
  const BreathingBorder({
    super.key,
    required this.child,
    required this.isBreathing,
    required this.borderColor,
    this.borderWidth = 1.5,
    this.showGlow = false,
    this.statusIndicator = 'loading', // 'loading', 'synced', 'error', or null
    this.borderRadius = 12,
    this.progressValue, // 0.0 to 1.0 for progress bar
  });

  final Widget child;
  final bool isBreathing;
  final Color borderColor;
  final double borderWidth;
  final bool showGlow;
  final String? statusIndicator;
  final double borderRadius;
  final double? progressValue; // If null, shows indeterminate progress

  @override
  State<BreathingBorder> createState() => _BreathingBorderState();
}

class _BreathingBorderState extends State<BreathingBorder>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _statusSpinController;
  late AnimationController _errorPulseController;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      duration: AnimationTimings.breathingDuration(),
      vsync: this,
    );

    _statusSpinController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.statusCircleRotateMs,
        ),
      ),
      vsync: this,
    );

    _errorPulseController = AnimationController(
      duration: Duration(
        milliseconds: AnimationTimings.apply(
          AnimationTimings.errorPulseMs,
        ),
      ),
      vsync: this,
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(BreathingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBreathing != oldWidget.isBreathing ||
        widget.statusIndicator != oldWidget.statusIndicator) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isBreathing) {
      _breathingController.repeat(reverse: true);
      if (widget.statusIndicator == 'loading') {
        _statusSpinController.repeat();
      } else {
        _statusSpinController.stop();
      }
      _errorPulseController.stop();
    } else {
      _breathingController.stop();
      _statusSpinController.stop();

      if (widget.statusIndicator == 'error') {
        _errorPulseController.repeat(reverse: true);
      } else {
        _errorPulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _statusSpinController.dispose();
    _errorPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Border + breathing animation
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final borderColor = widget.borderColor.withOpacity(
              0.2 + (_breathingController.value * 0.8), // Breathe from 0.2 to 1.0
            );

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: widget.borderWidth,
                ),
                boxShadow: widget.showGlow && widget.isBreathing
                    ? [
                        BoxShadow(
                          color: widget.borderColor.withOpacity(
                            0.2 * _breathingController.value,
                          ),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: widget.child,
        ),

        // Status indicator circle (top-right)
        if (widget.statusIndicator != null)
          Positioned(
            top: 8,
            right: 8,
            child: _buildStatusIndicator(),
          ),

        // Progress bar (bottom, if showing)
        if (widget.isBreathing && widget.progressValue == null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildIndeterminateProgress(),
          ),

        // Determinate progress bar
        if (widget.isBreathing && widget.progressValue != null)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              height: 2,
              width: MediaQuery.of(context).size.width * widget.progressValue!,
              decoration: BoxDecoration(
                color: widget.borderColor.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(widget.borderRadius),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator() {

    switch (widget.statusIndicator) {
      case 'loading':
        return RotationTransition(
          turns: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: _statusSpinController, curve: Curves.linear),
          ),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.borderColor.withOpacity(0.6),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.borderColor.withOpacity(0.4),
                ),
              ),
            ),
          ),
        );

      case 'synced':
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.2),
            border: Border.all(
              color: Colors.green,
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.check,
              size: 10,
              color: Colors.green,
            ),
          ),
        );

      case 'error':
        return AnimatedBuilder(
          animation: _errorPulseController,
          builder: (context, child) {
            final opacity = 0.4 + (_errorPulseController.value * 0.6);
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2 * opacity),
                border: Border.all(
                  color: Colors.red.withOpacity(opacity),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.close,
                  size: 10,
                  color: Colors.red.withOpacity(opacity),
                ),
              ),
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIndeterminateProgress() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        // Indeterminate progress: shimmer moves left-to-right
        final offset = _breathingController.value * 2 - 1;

        return Opacity(
          opacity: 0.3,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(widget.borderRadius),
                bottomRight: Radius.circular(widget.borderRadius),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(offset - 0.5, 0),
                  end: Alignment(offset + 0.5, 0),
                  colors: [
                    Colors.transparent,
                    widget.borderColor.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Container(
                color: widget.borderColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
