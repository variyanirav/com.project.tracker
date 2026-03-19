import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme provider for managing dark/light mode
/// Default is dark mode for MVP
final themeProvider = StateProvider<bool>((ref) {
  return true; // true = dark mode, false = light mode
});

/// Provider to toggle theme
final toggleThemeProvider = Provider((ref) {
  return () {
    ref.read(themeProvider.notifier).state = !ref.read(themeProvider);
  };
});
