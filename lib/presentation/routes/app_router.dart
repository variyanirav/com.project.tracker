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

/// Selected project ID provider (for navigation to project detail)
/// Used to pass projectId when navigating to project detail screen
final selectedProjectIdProvider = StateProvider<String?>((ref) {
  return null;
});

/// Navigation helper - changes the current screen
final navigateToProvider = Provider((ref) {
  return (String route, {String? projectId}) {
    if (projectId != null) {
      ref.read(selectedProjectIdProvider.notifier).state = projectId;
    }
    ref.read(currentScreenProvider.notifier).state = route;
  };
});
