import 'package:flutter/material.dart';

// Design Language: Standardized opacity tiers for consistent visual hierarchy
// See DESIGN_LANGUAGE.md section "Color System" for specifications
// Primary: 1.0 (100%) - Primary text, icons, interactive elements
// Secondary: 0.7 (70%) - Secondary text, less important information
// Tertiary: 0.5 (50%) - Hints, disabled states, subtle elements
// Disabled: 0.3 (30%) - Severely disabled, very subtle backgrounds

extension OpacityTiers on Color {
  /// Primary opacity tier: 100% - for primary text, icons, interactive elements
  Color get opacityPrimary => withValues(alpha: 1.0);

  /// Secondary opacity tier: 70% - for secondary text and less important info
  Color get opacitySecondary => withValues(alpha: 0.7);

  /// Tertiary opacity tier: 50% - for hints, subtle elements
  Color get opacityTertiary => withValues(alpha: 0.5);

  /// Disabled opacity tier: 30% - for disabled states and very subtle backgrounds
  Color get opacityDisabled => withValues(alpha: 0.3);

  /// Custom opacity tier with explicit alpha value (0.0-1.0)
  Color withOpacityTier(double opacity) => withValues(alpha: opacity.clamp(0, 1));
}

/// Predefined opacity constants for consistent usage throughout the app
abstract final class OpacityConstants {
  static const double primary = 1.0;      // 100%
  static const double secondary = 0.7;    // 70%
  static const double tertiary = 0.5;     // 50%
  static const double disabled = 0.3;     // 30%
  
  // Common fractional opacities for specific use cases
  static const double hoverOverlay = 0.08;    // Subtle hover backgrounds
  static const double divider = 0.08;         // Light divider lines
  static const double skeleton = 0.12;        // Skeleton loading states
  static const double shadow = 0.12;          // Shadow overlays
}
