import 'package:flutter/material.dart';
import '../core/database/activity_database.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void init() {
    if (_initialized) return;
    _initialized = true;
    final saved = ActivityDatabase.getGoal('theme_mode', defaultValue: 0);
    _themeMode = saved == 1 ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    ActivityDatabase.saveGoal('theme_mode', _themeMode == ThemeMode.dark ? 1 : 0);
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    ActivityDatabase.saveGoal('theme_mode', mode == ThemeMode.dark ? 1 : 0);
    notifyListeners();
  }
}
