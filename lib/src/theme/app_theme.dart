import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color surfaceBackground = Color(0xFF21262D);
  static const Color borderColor = Color(0xFF30363D);
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentPurple = Color(0xFFBB86FC);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFF85149);
  static const Color textPrimary = Color(0xFFC9D1D9);
  static const Color textSecondary = Color(0xFF8B949E);

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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary),
      ),
    );
  }
}
