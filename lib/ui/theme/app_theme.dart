import 'package:flutter/material.dart';

class AppTheme {
  // Dark Mode Palette
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryViolet = Color(0xFF7C4DFF);
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color cardBackground = Color(0xFF181F2C);
  static const Color surfaceElevated = Color(0xFF222B3D);
  static const Color borderSubtle = Color(0xFF2E3A52);
  static const Color textMuted = Color(0xFF8E9EB5);

  // Light Mode Palette
  static const Color lightPrimary = Color(0xFF0284C7); // Vibrant Deep Sky/Cyan
  static const Color lightSecondary = Color(0xFF6D28D9); // Deep Violet
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightCardBackground = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextPrimary = Color(0xFF0F172A);

  // Dynamic Theme Helpers
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? primaryCyan : lightPrimary;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? primaryViolet : lightSecondary;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? borderSubtle : lightBorder;
  }

  static Color getTextMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textMuted : lightTextMuted;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surfaceElevated : lightSurfaceElevated;
  }

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightCardBackground,
        error: Color(0xFFDC2626),
      ),
      cardTheme: CardThemeData(
        color: lightCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: lightTextMuted, fontSize: 13),
        labelStyle: const TextStyle(color: lightPrimary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Dark Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: primaryViolet,
        surface: cardBackground,
        error: Color(0xFFFF5252),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: primaryCyan, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
