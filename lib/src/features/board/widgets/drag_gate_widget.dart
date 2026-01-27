import 'package:flutter/material.dart';

/// A widget that gates drag gestures based on pointer movement distance.
/// 
/// This widget prevents unintended drag initiation during scroll interactions
/// by tracking pointer movement. If the pointer moves more than [distanceThreshold]
/// pixels from its initial position, drag gestures are absorbed (disabled),
/// allowing scroll gestures to take priority.
/// 
/// The gate is applied per-column to all nested widgets.
class DragGateWidget extends StatefulWidget {
  final Widget child;
  final double distanceThreshold;

  const DragGateWidget({
    super.key,
    required this.child,
    this.distanceThreshold = 15.0,
  });

  @override
  State<DragGateWidget> createState() => _DragGateWidgetState();
}

class _DragGateWidgetState extends State<DragGateWidget> {
  late Offset _initialPointerPosition;
  bool _canDrag = true;
  bool _isPointerDown = false;

  void _onPointerDown(PointerDownEvent event) {
    _initialPointerPosition = event.position;
    _isPointerDown = true;
    _canDrag = true;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerDown) return;

    final distance = (_initialPointerPosition - event.position).distance;

    if (distance > widget.distanceThreshold && _canDrag) {
      setState(() {
        _canDrag = false;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _isPointerDown = false;
    if (!_canDrag) {
      setState(() {
        _canDrag = true;
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isPointerDown = false;
    if (!_canDrag) {
      setState(() {
        _canDrag = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AbsorbPointer(
        absorbing: !_canDrag,
        child: widget.child,
      ),
    );
  }
}
