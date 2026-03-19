import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App routing configuration
class AppRouter {
  // Navigation routes
  static const String dashboard = 'dashboard';
  static const String projectList = 'project_list';
  static const String projectDetail = 'project_detail';
  static const String reports = 'reports';
  static const String settings = 'settings';
}

/// Current active screen provider
/// Tracks which screen is currently displayed
final currentScreenProvider = StateProvider<String>((ref) {
  return AppRouter.dashboard;
});

/// Navigation helper - changes the current screen
final navigateToProvider = Provider((ref) {
  return (String route) {
    ref.read(currentScreenProvider.notifier).state = route;
  };
});
