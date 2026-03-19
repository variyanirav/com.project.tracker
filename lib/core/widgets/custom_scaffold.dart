import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../constants/app_constants.dart';
import '../../presentation/routes/app_router.dart';

/// Custom scaffold with left navigation rail for desktop layout
/// Integrates with Riverpod navigation system
class CustomScaffold extends ConsumerWidget {
  final String activeRoute;
  final Widget child;
  final Widget? trailing;

  const CustomScaffold({
    super.key,
    required this.activeRoute,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navigation items
    final navItems = [
      _NavItem(icon: Icons.dashboard, label: 'Dashboard', route: 'dashboard'),
      _NavItem(icon: Icons.list_alt, label: 'Projects', route: 'project_list'),
      _NavItem(icon: Icons.bar_chart, label: 'Reports', route: 'reports'),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Left Navigation Rail
          Container(
            width: AppConstants.navRailWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo / App Icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacing16,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.roundRadius,
                      ),
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: navItems.map((item) {
                        final isSelected = activeRoute == item.route;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacing4,
                            horizontal: AppConstants.spacing8,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(currentScreenProvider.notifier).state =
                                  item.route;
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.brandPrimary.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.roundRadius,
                                  ),
                                ),
                                padding: const EdgeInsets.all(
                                  AppConstants.spacing12,
                                ),
                                child: Tooltip(
                                  message: item.label,
                                  child: Icon(
                                    item.icon,
                                    color: isSelected
                                        ? AppColors.brandPrimary
                                        : (isDark
                                              ? AppColors.darkTextTertiary
                                              : AppColors.lightTextTertiary),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Trailing widget (Settings, etc)
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacing16,
                    ),
                    child: trailing!,
                  ),
              ],
            ),
          ),

          // Main Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Navigation item model
class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  _NavItem({required this.icon, required this.label, required this.route});
}
