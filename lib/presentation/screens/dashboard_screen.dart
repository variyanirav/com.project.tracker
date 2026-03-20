import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_button.dart';
import '../../core/theme/text_styles.dart';
import '../providers/theme_provider.dart';
import '../providers/project_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';
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
    // Watch providers for real-time data
    final projectsAsync = ref.watch(projectsProvider);
    final timerAsync = ref.watch(timerProvider);

    // Check if we have projects
    final hasProjects =
        projectsAsync.whenData((projects) => projects.isNotEmpty).value ??
        false;

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
                      // Save to database
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
                ref.read(themeProvider.notifier).toggle();
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

            // Running Timer Card - Only show if timer is actively running
            if (timerAsync.isRunning &&
                timerAsync.sessionId != null &&
                timerAsync.taskId != null &&
                timerAsync.projectId != null)
              Column(
                children: [
                  // Fetch and display actual project and task names
                  FutureBuilder<(String?, String?)>(
                    future: _getProjectAndTaskNames(
                      ref,
                      timerAsync.projectId,
                      timerAsync.taskId,
                    ),
                    builder: (context, snapshot) {
                      // While loading, show fallback but still with real task info if available
                      final projectName = snapshot.hasData
                          ? snapshot.data?.$1
                          : (snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading...'
                                : 'Unknown Project');
                      final taskName = snapshot.hasData
                          ? snapshot.data?.$2
                          : (snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading...'
                                : 'Unknown Task');

                      return RunningTimerCard(
                        projectName: projectName ?? 'Unknown Project',
                        taskName: taskName ?? 'Unknown Task',
                        elapsedTime: _formatElapsedTime(
                          timerAsync.elapsedSeconds,
                        ),
                        onPausePressed: () {
                          ref.read(timerProvider.notifier).pauseTimer();
                        },
                        onStopPressed: () async {
                          await ref.read(timerProvider.notifier).stopTimer();
                          // Timer state change will automatically hide the card
                          // because isTimerRunning will become false
                        },
                      );
                    },
                  ),
                  SizedBox(height: AppConstants.spacing32),
                ],
              )
            else
              SizedBox(height: AppConstants.spacing32),

            // "Add New Project" Button - Always visible for empty state
            if (!hasProjects)
              Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.brandPrimary,
                        ),
                        SizedBox(height: AppConstants.spacing16),
                        Text('No Projects Yet', style: AppTextStyles.heading2),
                        SizedBox(height: AppConstants.spacing8),
                        Text(
                          'Create your first project to get started',
                          style: AppTextStyles.bodyMedium,
                        ),
                        SizedBox(height: AppConstants.spacing24),
                        AppButton.primary(
                          label: '+ Create First Project',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => CreateProjectDialog(
                                onCreatePressed:
                                    (title, description, emoji) async {
                                      try {
                                        await ref.read(
                                          createProjectProvider(
                                            CreateProjectParams(
                                              name: title,
                                              description: description,
                                              color: emoji,
                                            ),
                                          ).future,
                                        );
                                        ref.invalidate(projectsProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Project "$title" created!',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error creating project: $e',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing32),
                ],
              ),

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
                          onCreatePressed: (title, description, emoji) async {
                            try {
                              await ref.read(
                                createProjectProvider(
                                  CreateProjectParams(
                                    name: title,
                                    description: description,
                                    color: emoji,
                                  ),
                                ).future,
                              );

                              // Invalidate cache to fetch new data
                              ref.invalidate(projectsProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Project "$title" created!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating project: $e'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacing12),
            ],

            // Projects Grid or Empty State
            if (hasProjects)
              projectsAsync.when(
                data: (projects) {
                  if (projects.isEmpty) {
                    return SizedBox.shrink();
                  }

                  // Take up to 3 projects for dashboard display
                  final displayedProjects = projects.take(3).toList();

                  return LayoutBuilder(
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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnCount,
                                  childAspectRatio: 1.1,
                                  mainAxisSpacing: AppConstants.spacing16,
                                  crossAxisSpacing: AppConstants.spacing16,
                                ),
                            itemCount: displayedProjects.length,
                            itemBuilder: (context, index) {
                              final project = displayedProjects[index];
                              final projectHours = ref.watch(
                                projectTotalHoursProvider(project.id),
                              );

                              return projectHours.when(
                                data: (hours) {
                                  final tasksList = ref.watch(
                                    tasksByProjectProvider(project.id),
                                  );

                                  return tasksList.when(
                                    data: (tasks) {
                                      // Convert tasks to RecentTask
                                      final recentTasks = tasks
                                          .take(2)
                                          .map(
                                            (task) => RecentTask(
                                              name: task.taskName,
                                              status: task.status,
                                            ),
                                          )
                                          .toList();

                                      return ProjectCard(
                                        title: project.name,
                                        description: project.description ?? '',
                                        hours: _formatHours(hours),
                                        avatarEmoji: project.color ?? '📁',
                                        recentTasks: recentTasks,
                                        onViewPressed: () {
                                          // Navigate to project detail screen with project ID
                                          final navigate = ref.read(
                                            navigateToProvider,
                                          );
                                          navigate(
                                            AppRouter.projectDetail,
                                            projectId: project.id,
                                          );
                                        },
                                      );
                                    },
                                    loading: () => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (err, stack) => ProjectCard(
                                      title: project.name,
                                      description: project.description ?? '',
                                      hours: 'Error',
                                      avatarEmoji: project.color ?? '📁',
                                      recentTasks: [],
                                      onViewPressed: () {
                                        final navigate = ref.read(
                                          navigateToProvider,
                                        );
                                        navigate(
                                          AppRouter.projectDetail,
                                          projectId: project.id,
                                        );
                                      },
                                    ),
                                  );
                                },
                                loading: () =>
                                    Center(child: CircularProgressIndicator()),
                                error: (err, stack) => ProjectCard(
                                  title: project.name,
                                  description: project.description ?? '',
                                  hours: 'Error',
                                  avatarEmoji: project.color ?? '📁',
                                  recentTasks: [],
                                  onViewPressed: () {
                                    final navigate = ref.read(
                                      navigateToProvider,
                                    );
                                    navigate(
                                      AppRouter.projectDetail,
                                      projectId: project.id,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: AppConstants.spacing32),
                          // View All Projects Link
                          if (projects.length > 3)
                            Center(
                              child: InkWell(
                                onTap: () {
                                  // Navigate to project list page
                                  final navigate = ref.read(navigateToProvider);
                                  navigate(AppRouter.projectList);
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
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Error loading projects: $err')),
              ),
          ],
        ),
      ),
    );
  }

  /// Format elapsed time in seconds to HH:MM:SS format
  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format hours (double) to readable format like "12h 45m"
  String _formatHours(double hours) {
    final wholeHours = hours.toInt();
    final minutes = ((hours - wholeHours) * 60).toInt();
    if (wholeHours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${wholeHours}h';
    }
    return '${wholeHours}h ${minutes}m';
  }

  /// Get project and task names from their IDs
  Future<(String?, String?)> _getProjectAndTaskNames(
    WidgetRef ref,
    String? projectId,
    String? taskId,
  ) async {
    String? projectName;
    String? taskName;

    if (projectId != null) {
      try {
        final projects = await ref.watch(projectsProvider.future);
        final project = projects.where((p) => p.id == projectId).firstOrNull;
        projectName = project?.name;
      } catch (e) {
        projectName = null;
      }
    }

    if (taskId != null) {
      try {
        final tasks = await ref.watch(tasksProvider.future);
        final task = tasks.where((t) => t.id == taskId).firstOrNull;
        taskName = task?.taskName;
      } catch (e) {
        taskName = null;
      }
    }

    return (projectName, taskName);
  }
}
