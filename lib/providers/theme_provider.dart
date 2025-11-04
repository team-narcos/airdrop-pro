import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('themeMode') ?? 'system';
      state = _parseThemeMode(savedMode);
      print('[ThemeProvider] Loaded theme: $savedMode');
    } catch (e) {
      print('[ThemeProvider] Error loading theme: $e');
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (state == themeMode) return;
    
    state = themeMode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', _themeModeToString(themeMode));
      print('[ThemeProvider] Theme saved: ${_themeModeToString(themeMode)}');
    } catch (e) {
      print('[ThemeProvider] Error saving theme: $e');
    }
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setTheme(newMode);
  }
  
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
