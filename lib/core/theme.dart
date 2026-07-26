import 'package:flutter/material.dart';

class AppTheme {
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8C5A);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: accentLight,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accent,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: accentLight,
        surface: const Color(0xFF1E1E2E),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121220),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E1E2E),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: accent,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
