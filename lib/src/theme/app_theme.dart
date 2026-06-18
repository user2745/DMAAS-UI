import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette based on Activities Brand Media Kit
  static const Color darkBackground = Color(0xFF0F141B); // Charcoal
  static const Color cardBackground = Color(0xFF0E1928); // Deep Navy
  static const Color surfaceBackground = Color(0xFF334155); // Steel Gray
  static const Color borderColor = Color(0xFF64748B); // Light Gray
  static const Color accentBlue = Color(0xFF3882F6); // Primary Blue
  static const Color accentGreen = Color(0xFF22C55E); // Success Green
  static const Color accentPurple = Color(0xFF8B5CF6); // In Progress Purple
  static const Color accentOrange = Color(0xFFD97706); // At Risk Orange
  static const Color accentRed = Color(0xFFDC2626); // Overdue Red
  static const Color textPrimary = Color(0xFFF8FAFC); // Off White
  static const Color textSecondary = Color(0xFFCBD5E1); // Silver

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: accentBlue,
      secondary: accentPurple,
      surface: surfaceBackground,
      error: accentRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: cardBackground,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withAlpha(102),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        filled: true,
        fillColor: surfaceBackground,
        hintStyle: const TextStyle(color: textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceBackground,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: borderColor),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentBlue,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentBlue,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
      ),
      textTheme: baseTextTheme,
    );
  }
}
