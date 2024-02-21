import 'package:chat_app/theme/dark_theme.dart';
import 'package:chat_app/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkTheme;

  set themeData (ThemeData themeData) {
    _themeData = themeData;
    _saveThemePreference();
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightTheme) {
      themeData = darkTheme;
    } else {
      themeData = lightTheme;
    }
  }

  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeData = isDarkMode ? darkTheme : lightTheme;
    notifyListeners();
  }

  void _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}