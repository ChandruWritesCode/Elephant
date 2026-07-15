import 'package:flutter/material.dart';
import 'package:mobile/themes/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeType _currentTheme = ThemeType.frost;
  bool _isInitialized = false;

  ThemeType get currentTheme => _currentTheme;
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeIndex = prefs.getInt('app_theme');

    if (savedThemeIndex != null &&
        savedThemeIndex >= 0 &&
        savedThemeIndex < ThemeType.values.length) {
      _currentTheme = ThemeType.values[savedThemeIndex];
    } else {
      _currentTheme = ThemeType.frost;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setTheme(ThemeType themeType) async {
    if (_currentTheme != themeType) {
      _currentTheme = themeType;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_theme', themeType.index);
    }
  }
}
