import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/project_list_screen.dart';
import 'presentation/screens/project_detail_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/routes/app_router.dart';

/// Main application widget
class TimeTrackerApp extends ConsumerWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final currentScreen = ref.watch(currentScreenProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _buildScreen(currentScreen, ref),
    );
  }

  /// Build the appropriate screen based on current route
  Widget _buildScreen(String currentScreen, WidgetRef ref) {
    switch (currentScreen) {
      case AppRouter.dashboard:
        return const DashboardScreen();
      case AppRouter.projectList:
        return const ProjectListScreen();
      case AppRouter.projectDetail:
        return const ProjectDetailScreen();
      case AppRouter.reports:
        return const ReportsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
