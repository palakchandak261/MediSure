import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';

/// ThemeProvider — manages light/dark mode across the app.
/// Persists preference to LocalStorageService.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider()
      : _themeMode = LocalStorageService.getThemeMode() == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    LocalStorageService.saveThemeMode(isDark ? 'dark' : 'light');
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    LocalStorageService.saveThemeMode(isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
