import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/core/utils/shared_preferences_helper.dart';

/// State notifier for theme management
class ThemeStateNotifier extends StateNotifier<bool> {
  ThemeStateNotifier() : super(true); // Default to dark mode

  /// Initialize theme from preferences
  Future<void> initialize() async {
    final savedTheme = await SharedPreferencesHelper.getTheme();
    // Convert string theme to bool (true for dark, false for light)
    state = savedTheme != 'light';
  }

  /// Toggle between dark and light mode
  Future<void> toggle() async {
    final newState = !state;
    state = newState;
    final themeString = newState ? 'dark' : 'light';
    await SharedPreferencesHelper.saveTheme(themeString);
  }

  /// Set specific theme
  Future<void> setTheme(bool isDarkMode) async {
    state = isDarkMode;
    final themeString = isDarkMode ? 'dark' : 'light';
    await SharedPreferencesHelper.saveTheme(themeString);
  }
}

/// Theme provider for managing dark/light mode
/// true = dark mode, false = light mode
final themeProvider = StateNotifierProvider<ThemeStateNotifier, bool>((ref) {
  return ThemeStateNotifier();
});

/// Provider to get current theme name
final themeNameProvider = Provider<String>((ref) {
  final isDarkMode = ref.watch(themeProvider);
  return isDarkMode ? 'Dark' : 'Light';
});
