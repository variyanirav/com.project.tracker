import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_button.dart';
import '../../core/theme/text_styles.dart';
import '../providers/theme_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dashboard/daily_progress_card.dart';
import '../widgets/dashboard/project_card.dart' show ProjectCard, RecentTask;
import '../widgets/dashboard/running_timer_card.dart';
import '../widgets/dialogs/create_project_dialog.dart';
import '../widgets/dialogs/daily_goal_settings_dialog.dart';

/// Dashboard screen - Main landing page
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample data - will be replaced with actual data from providers
    final hasProjects = true; // TODO: Get from projectsProvider
    final isTimerRunning = false; // TODO: Get from activeTimerProvider

    return CustomScaffold(
      activeRoute: AppRouter.dashboard,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Settings Button
          Tooltip(
            message: 'Daily Goal Settings',
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DailyGoalSettingsDialog(
                    currentGoalHours: 8,
                    onSavePressed: (hours) {
                      // TODO: Save to SharedPreferences/local DB
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Daily goal set to $hours hours'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(width: AppConstants.spacing8),
          // Theme Toggle Button
          Tooltip(
            message: ref.watch(themeProvider) ? 'Light Mode' : 'Dark Mode',
            child: IconButton(
              icon: Icon(
                ref.watch(themeProvider) ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).state = !ref.read(
                  themeProvider,
                );
              },
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard Overview', style: AppTextStyles.heading2),
                    SizedBox(height: AppConstants.spacing4),
                    Text(
                      'Welcome back! Tracking your efficiency today.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.brandPrimary,
                  child: Text(
                    'JD',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing32),

            // Daily Progress Card
            DailyProgressCard(),

            SizedBox(height: AppConstants.spacing32),

            // Running Timer Card (visible only when timer is running)
            if (isTimerRunning)
              Column(
                children: [
                  RunningTimerCard(
                    projectName: 'Mobile App Redesign',
                    taskName: 'Design Refinement',
                    elapsedTime: '02:15:45',
                    onPausePressed: () {
                      // TODO: Implement pause
                    },
                    onStopPressed: () {
                      // TODO: Implement stop
                    },
                  ),
                  SizedBox(height: AppConstants.spacing32),
                ],
              )
            else
              SizedBox(height: AppConstants.spacing32),

            // "Your Projects" Section with "Add New Project" Button
            if (hasProjects) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Projects', style: AppTextStyles.titleLarge),
                  AppButton.primary(
                    label: '+ Add New Project',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CreateProjectDialog(
                          onCreatePressed: (title, description, emoji) {
                            // TODO: Save to database via provider
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Project "$title" created!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacing12),
            ] else ...[
              Text('Your Projects', style: AppTextStyles.titleLarge),
              SizedBox(height: AppConstants.spacing12),
            ],

            // Projects Grid or Empty State
            if (hasProjects)
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final columnCount = maxWidth > 1200
                      ? 3
                      : maxWidth > 800
                      ? 2
                      : 1;

                  return Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          childAspectRatio: 1.1,
                          mainAxisSpacing: AppConstants.spacing16,
                          crossAxisSpacing: AppConstants.spacing16,
                        ),
                        itemCount: 3, // Sample data
                        itemBuilder: (context, index) {
                          final projects = [
                            {
                              'title': 'Mobile App Redesign',
                              'description':
                                  'Refresh the user interface and UX',
                              'emoji': '📱',
                              'hours': '12h 45m',
                              'tasks': [
                                RecentTask(
                                  name: 'Design mockups',
                                  status: 'Complete',
                                ),
                                RecentTask(
                                  name: 'User testing',
                                  status: 'In Progress',
                                ),
                              ],
                            },
                            {
                              'title': 'Backend API',
                              'description': 'RESTful API implementation',
                              'emoji': '⚙️',
                              'hours': '28h 30m',
                              'tasks': [
                                RecentTask(
                                  name: 'Authentication setup',
                                  status: 'Complete',
                                ),
                                RecentTask(
                                  name: 'Database schema design',
                                  status: 'In Review',
                                ),
                              ],
                            },
                            {
                              'title': 'Design System',
                              'description': 'Component library & tokens',
                              'emoji': '🎨',
                              'hours': '8h 15m',
                              'tasks': [
                                RecentTask(
                                  name: 'Color tokens',
                                  status: 'To Do',
                                ),
                                RecentTask(
                                  name: 'Typography system',
                                  status: 'In Progress',
                                ),
                              ],
                            },
                          ];

                          final project = projects[index];
                          return ProjectCard(
                            title: project['title'] as String,
                            description: project['description'] as String,
                            hours: project['hours'] as String,
                            avatarEmoji: project['emoji'] as String,
                            recentTasks: project['tasks'] as List<RecentTask>,
                            onViewPressed: () {
                              // Navigate to project detail screen using Riverpod
                              // TODO: Pass actual project data via arguments
                              ref.read(currentScreenProvider.notifier).state =
                                  AppRouter.projectDetail;
                            },
                          );
                        },
                      ),
                      SizedBox(height: AppConstants.spacing32),
                      // View All Projects Link
                      Center(
                        child: InkWell(
                          onTap: () {
                            // Navigate to project list page
                            ref.read(currentScreenProvider.notifier).state =
                                AppRouter.projectList;
                          },
                          child: Text(
                            'View All Projects →',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              // Empty State
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppConstants.spacing40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.roundRadius,
                          ),
                        ),
                        child: Icon(
                          Icons.folder_open_outlined,
                          size: 40,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing24),
                      Text('No Projects Yet', style: AppTextStyles.titleMedium),
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        'Create your first project to start tracking time',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing24),
                      AppButton.primary(
                        label: '+ Create First Project',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CreateProjectDialog(
                              onCreatePressed: (title, description, emoji) {
                                // TODO: Save to database via provider
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Project "$title" created!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
