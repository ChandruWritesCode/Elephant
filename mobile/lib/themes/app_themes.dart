import 'package:flutter/material.dart';

enum ThemeType { frost, aura, onyx, nebula }

class AppThemes {
  static final ThemeData frost = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF007AFF),
      surface: Color(0x99FFFFFF), 
      onSurface: Colors.black87,
    ),
    useMaterial3: true,
  );

  static final ThemeData aura = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFBF7),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF8A65),
      surface: Color(0x99FFF0E5),
      onSurface: Color(0xFF3E2723),
    ),
    useMaterial3: true,
  );

  static final ThemeData onyx = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE0E0E0),
      surface: Color(0x991E1E1E),
      onSurface: Colors.white,
    ),
    useMaterial3: true,
  );

  static final ThemeData nebula = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0914),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8A2BE2), 
      surface: Color(0x99191330),
      onSurface: Color(0xFFE6E6FA),
    ),
    useMaterial3: true,
  );

  static ThemeData getTheme(ThemeType type) {
    switch (type) {
      case ThemeType.frost:
        return frost;
      case ThemeType.aura:
        return aura;
      case ThemeType.onyx:
        return onyx;
      case ThemeType.nebula:
        return nebula;
    }
  }
}
