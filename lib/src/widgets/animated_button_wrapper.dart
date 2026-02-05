import 'package:flutter/material.dart';

// Design Language: Micro-interactions for all clickable elements
// See DESIGN_LANGUAGE.md section "Micro-interactions" for timing and scale specifications
// Hover: scale 1→1.02 (150ms easeOutCubic)
// Press: scale 1→0.95 (100ms easeOutCubic)

/// Wraps any button or clickable widget with smooth scale animations.
/// 
/// Usage:
/// ```dart
/// AnimatedButtonWrapper(
///   child: FilledButton(onPressed: () {}, child: Text('Click')),
/// )
/// ```
class AnimatedButtonWrapper extends StatefulWidget {
  const AnimatedButtonWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AnimatedButtonWrapper> createState() => _AnimatedButtonWrapperState();
}

class _AnimatedButtonWrapperState extends State<AnimatedButtonWrapper>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _hoverScale;
  late Animation<double> _pressScale;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _hoverScale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine hover and press scales
    double scale = 1.0;
    if (_isPressed) {
      scale = _pressScale.value;
    } else if (_isHovered) {
      scale = _hoverScale.value;
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _pressController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _pressController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _pressController.reverse();
        },
        child: Transform.scale(
          scale: scale,
          child: widget.child,
        ),
      ),
    );
  }
}
