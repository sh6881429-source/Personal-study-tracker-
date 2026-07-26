import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/core/services/storage_service.dart';

/// Key for storing theme mode preference.
const String _themeModeKey = 'app_theme_mode';

/// ── Theme Mode Notifier ──
/// Manages user theme selection and persists it in local storage.
/// Defaults to Light Mode as requested.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final savedMode = StorageService.getString(_themeModeKey);
    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        case 'system':
          state = ThemeMode.system;
          break;
      }
    } else {
      // Explicit default: Light Mode
      state = ThemeMode.light;
    }
  }

  /// Sets the theme mode and persists the preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await StorageService.setString(_themeModeKey, mode.name);
  }

  /// Toggles between light and dark themes.
  Future<void> toggleTheme(BuildContext context) async {
    final isDarkMode = state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

/// Provider for managing ThemeMode.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
