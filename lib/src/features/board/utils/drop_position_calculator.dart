import 'package:flutter/material.dart';

/// Simple drop position calculator.
///
/// Given a list of visible (non-collapsed) card rects and the drag pointer
/// position, returns the insertion index (0 = before first, length = after last).
class DropPositionCalculator {
  /// Returns the insertion index based on which card midpoint the drag Y is past.
  ///
  /// Walk through the cards top-to-bottom. For each card, if the drag Y is
  /// above its vertical midpoint, insert before it. Otherwise continue.
  /// If we pass all cards, insert at the end.
  static int calculate({
    required double dragY,
    required List<Rect> visibleCardRects,
  }) {
    for (int i = 0; i < visibleCardRects.length; i++) {
      final midY = visibleCardRects[i].top +
          visibleCardRects[i].height / 2;
      if (dragY < midY) return i;
    }
    return visibleCardRects.length;
  }
}
