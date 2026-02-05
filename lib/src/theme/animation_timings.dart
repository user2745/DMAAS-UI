/// Animation timing constants for micro-interactions
/// 
/// This file defines all animation durations used throughout the app's micro-interaction patterns.
/// Timings are designed to feel responsive without jarring. Adjust GLOBALLY via the A/B test flags.
///
/// Timing Philosophy:
/// - Hover reveal: 150-200ms (feel responsive)
/// - State transitions: 200-300ms (feel intentional)
/// - Loading/breathing: 1.2-1.5s (calm, not urgent)
/// - Deletion undo window: 5s (slow enough for safety, fast enough for flow)
/// - Progress indicators: 400-600ms loops (meditative)

class AnimationTimings {
  /// A/B testing flags to globally adjust animation feel
  /// Set these to false to revert to "default" timings if adjusted versions feel off
  static const bool useSlowerAnimations = false; // ×1.2 all durations if true
  static const bool useFasterAnimations = false; // ÷1.2 all durations if true

  // ==================== Hover & Reveal ==================== //
  /// Time to show hover affordance (background tint, border change)
  /// Perception: "I hovered, UI responded"
  static const int hoverRevealMs = 150;

  /// Time to hide hover affordance when cursor leaves
  /// Should match or be slightly faster than reveal
  static const int hoverHideMs = 100;

  // ==================== Status & State Transitions ==================== //
  /// Time for status badge chevron to rotate indicating valid moves
  static const int statusChevronRotateMs = 200;

  /// Time for drag shimmer to flow across card (drag momentum indicator)
  static const int dragShimmerDurationMs = 600;

  /// Time for drag shimmer to offset before repeating (trailing effect)
  static const int dragShimmerDelayMs = 50;

  /// Time for status pulse on valid drop (card expands then contracts)
  static const int statusPulseMs = 300;

  /// Time for rejection shimmer to reverse on invalid drop
  static const int rejectionReverseMs = 200;

  // ==================== Modal & Expansion ==================== //
  /// Time for field edit modal to slide up from ripple center
  static const int modalSlideUpMs = 300;

  /// Time for ripple to expand when clicking field chip
  static const int rippleExpandMs = 400;

  /// Time for chip to expand and show context label on click
  static const int chipExpandMs = 200;

  // ==================== Comments & Nesting ==================== //
  /// Time for indent line to animate in on comment hover
  static const int indentLineShowMs = 150;

  /// Time for comment thread to collapse/expand
  static const int threadCollapseMs = 300;

  /// Stagger delay between collapsing replies (creates cascade effect)
  static const int collapseStaggerMs = 20;

  /// Time to highlight comment ancestry on hover
  static const int ancestryHighlightMs = 100;

  // ==================== Loading & Breathing ==================== //
  /// Time for border color to breathe (idle → accent → idle)
  /// Longer duration = calmer feel, more "meditative"
  /// Try: 1200ms (calm), 1500ms (very calm), 900ms (slightly urgent)
  static const int breathingPulseMs = 1200;

  /// Time for progress bar to grow during long-running operations
  /// Indeterminate animation cycle time
  static const int progressBarCycleMs = 1500;

  /// Time for status circle to complete one rotation (loading state)
  static const int statusCircleRotateMs = 1500;

  /// Time for opacity to pulse in sync state error condition
  static const int errorPulseMs = 600;

  // ==================== Undo/Redo ==================== //
  /// Time for undo badge to fade in after change
  static const int undoBadgeFadeInMs = 150;

  /// Time to display undo badge before auto-fade
  static const int undoBadgeShowDurationMs = 2000;

  /// Time for undo badge to fade out
  static const int undoBadgeFadeOutMs = 200;

  /// Time for circular arrow to oscillate (indicates reversibility)
  static const int undoArrowOscillateMs = 600;

  /// Time for arrow rotation amplitude (how much it rotates)
  static const double undoArrowRotationDegrees = 20;

  /// Time for undo badge to expand when hovering (shows buttons)
  static const int undoBadgeExpandMs = 150;

  /// Time for arrows to spin 360° on undo/redo action
  static const int undoActionSpinMs = 300;

  /// Time for undo action to flash the element's color
  static const int undoActionFlashMs = 200;

  // ==================== Batch Selection ==================== //
  /// Time for selection corner square to appear
  static const int selectionCornerShowMs = 150;

  /// Time for checkmark to animate in
  static const int checkmarkScaleInMs = 150;

  /// Time for count badge to grow when added to selection
  static const int selectionCountGrowMs = 150;

  /// Time for drag selection badges to pulse in unison
  static const int dragSelectionPulseMs = 400;

  /// Stagger between each badge pulse during drag
  static const int dragSelectionStaggerMs = 50;

  /// Time for selection count color to shift (blue → purple at >3)
  static const int countColorShiftMs = 200;

  // ==================== Priority & Weight ==================== //
  /// Time for texture to appear on card (hover on high-priority)
  static const int priorityTextureShowMs = 150;

  /// Time for texture pattern to shift/animate
  static const int priorityTextureAnimateMs = 1000;

  /// Time for critical priority glow to pulse
  static const int criticalGlowPulseMs = 1200;

  /// Time for border to adjust on priority hover
  static const int priorityBorderAdjustMs = 200;

  // ==================== Deletion & Destruction ==================== //
  /// Total time for task to fade out + compress before deletion
  /// This is the undo window—must be long enough for user to react
  /// Try: 5000ms (5s, plenty of time), 3000ms (feels snappier), 7000ms (very safe)
  static const int deleteFadeOutMs = 5000;

  /// Time for other cards to slide up and fill deleted space
  static const int deleteReflowMs = 300;

  /// Stagger between each card sliding up
  static const int deleteReflowStaggerMs = 30;

  /// Time for undo button to appear on hover during fade
  static const int deleteUndoButtonShowMs = 200;

  /// Time for card to pulse red before final removal
  static const int deleteFinalPulseMs = 300;

  /// Time for undo toast to appear at bottom
  static const int deleteToastShowMs = 200;

  // ==================== Helper Methods ==================== //

  /// Apply A/B test multipliers to any duration
  /// Allows global "slow down" or "speed up" of all animations
  static int apply(int baseMs) {
    if (useSlowerAnimations) return (baseMs * 1.2).toInt();
    if (useFasterAnimations) return (baseMs / 1.2).toInt();
    return baseMs;
  }

  /// Get breathing animation duration with optional speed adjustment
  static Duration breathingDuration({double speedMultiplier = 1.0}) {
    return Duration(
      milliseconds: (apply(breathingPulseMs) * speedMultiplier).toInt(),
    );
  }

  /// Get deletion fade duration with optional speed adjustment
  static Duration deleteDuration({double speedMultiplier = 1.0}) {
    return Duration(
      milliseconds: (apply(deleteFadeOutMs) * speedMultiplier).toInt(),
    );
  }

  /// Get undo badge display duration (not affected by A/B test)
  /// Users need consistent time window regardless of animation speed
  static const Duration undoBadgeDuration = Duration(
    milliseconds: undoBadgeShowDurationMs,
  );

  /// Convert milliseconds to Duration with A/B test applied
  static Duration duration(int ms) => Duration(milliseconds: apply(ms));
}
