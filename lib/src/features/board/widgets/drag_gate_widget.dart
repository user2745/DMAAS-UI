import 'package:flutter/material.dart';

/// Inherited widget that provides drag gate state to descendants.
class DragGateProvider extends InheritedWidget {
  const DragGateProvider({
    required super.child,
    required this.canDrag,
  });

  final bool canDrag;

  static DragGateProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DragGateProvider>();
  }

  static DragGateProvider of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No DragGateProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DragGateProvider oldWidget) {
    return canDrag != oldWidget.canDrag;
  }
}

/// A widget that gates drag behavior based on pointer movement distance.
/// 
/// If the pointer moves more than [distanceThreshold] pixels before being
/// released, drag is disabled (allowing scroll). Otherwise, drag is enabled.
class DragGateWidget extends StatefulWidget {
  const DragGateWidget({
    required this.child,
    this.distanceThreshold = 15,
    super.key,
  });

  final Widget child;
  final double distanceThreshold;

  @override
  State<DragGateWidget> createState() => _DragGateWidgetState();
}

class _DragGateWidgetState extends State<DragGateWidget> {
  late Offset _initialPointerPosition;
  bool _canDrag = true;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: DragGateProvider(
        canDrag: _canDrag,
        child: AbsorbPointer(
          absorbing: !_canDrag,
          child: widget.child,
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _initialPointerPosition = event.position;
    setState(() => _canDrag = true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_canDrag) return; // Already disabled, no need to check further

    final distance = (event.position - _initialPointerPosition).distance;
    if (distance > widget.distanceThreshold) {
      setState(() => _canDrag = false);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Reset state on pointer up for next gesture
    setState(() => _canDrag = true);
  }
}
