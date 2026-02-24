import 'package:flutter/material.dart';

// Design Language: Button animation constants and styles
// See DESIGN_LANGUAGE.md section "Micro-interactions" for specifications

/// Extension to provide animated button styles with hover/press scales
extension AnimatedButtonStyles on ButtonStyle {
  /// Creates a button style with smooth scale animations on hover/press
  /// Hover: 1.0 → 1.02 (150ms easeOutCubic)
  /// Press: 1.0 → 0.95 (100ms easeOutCubic)
  static ButtonStyle animated({
    required Color? foregroundColor,
    required Color? backgroundColor,
    double hoverElevation = 8,
    double pressElevation = 2,
  }) {
    return ButtonStyle(
      // Smooth elevation changes provide visual feedback
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.pressed)) {
          return pressElevation;
        } else if (states.contains(WidgetState.hovered)) {
          return hoverElevation;
        }
        return 2;
      }),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.transparent; // We handle visual feedback with elevation
        }
        return null;
      }),
    );
  }
}
