import 'package:flutter/material.dart';

/// Utility class for calculating drop positions during drag-and-drop operations.
/// 
/// Determines the insertion index based on closest card proximity using
/// y-coordinate snapping to the nearest card.
class DropPositionCalculator {
  /// Calculates the closest card index for drop position based on drag offset.
  /// 
  /// Given a list of card global positions and a drag offset, this function
  /// determines which card the user is hovering over and returns the appropriate
  /// insertion index (snap-to-closest).
  /// 
  /// Parameters:
  /// - [dragOffset]: The global offset of the drag pointer
  /// - [cardGlobalPositions]: List of global Rect positions for each card
  /// - [columnScrollOffset]: The vertical scroll offset of the column
  /// 
  /// Returns: The insertion index (0-based), or the task count if dropping after last card
  static int calculateClosestCardIndex({
    required Offset dragOffset,
    required List<Rect> cardGlobalPositions,
    required double columnScrollOffset,
  }) {
    if (cardGlobalPositions.isEmpty) {
      return 0;
    }

    // Adjust drag offset for scroll position
    final adjustedDragY = dragOffset.dy + columnScrollOffset;

    double closestDistance = double.infinity;
    int closestIndex = 0;
    int insertAfterIndex = -1;

    // Find the card center closest to the drag position
    for (int i = 0; i < cardGlobalPositions.length; i++) {
      final cardRect = cardGlobalPositions[i];
      final cardCenterY = cardRect.top + (cardRect.height / 2);
      final distance = (adjustedDragY - cardCenterY).abs();

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
        
        // Determine if we're inserting before or after this card
        if (adjustedDragY > cardCenterY) {
          insertAfterIndex = i;
        }
      }
    }

    // If closest distance is measured and we're past the midpoint, insert after
    if (insertAfterIndex >= 0 && insertAfterIndex < cardGlobalPositions.length - 1) {
      return insertAfterIndex + 1;
    }

    // If we're hovering over the first card's upper half, insert at beginning
    if (closestIndex == 0 && adjustedDragY < cardGlobalPositions[0].center.dy) {
      return 0;
    }

    // Default: insert after the closest card (or at the end)
    return closestIndex + 1;
  }

  /// Calculates the relative position (0.0-1.0) of drag within the card list.
  /// 
  /// Useful for maintaining relative insertion position when moving between columns.
  /// 0.0 = before first card, 1.0 = after last card
  static double calculateRelativePosition({
    required Offset dragOffset,
    required List<Rect> cardGlobalPositions,
    required double columnScrollOffset,
  }) {
    if (cardGlobalPositions.isEmpty) {
      return 0.5; // Default to middle if no cards
    }

    final firstCardTop = cardGlobalPositions.first.top;
    final lastCardBottom = cardGlobalPositions.last.bottom;
    final totalHeight = lastCardBottom - firstCardTop;

    final adjustedDragY = dragOffset.dy + columnScrollOffset;
    final relativePosition = (adjustedDragY - firstCardTop) / totalHeight;

    return relativePosition.clamp(0.0, 1.0);
  }

  /// Converts relative position (0.0-1.0) to absolute card index in target column.
  /// 
  /// Useful when dragging between columns to maintain relative position.
  static int relativePositionToIndex({
    required double relativePosition,
    required int targetTaskCount,
  }) {
    if (targetTaskCount == 0) {
      return 0;
    }

    final index = (relativePosition * targetTaskCount).round();
    return index.clamp(0, targetTaskCount);
  }
}
