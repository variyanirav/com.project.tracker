import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_button.dart';
import '../../core/theme/text_styles.dart';
import '../providers/theme_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dashboard/project_card.dart' show ProjectCard, RecentTask;
import '../widgets/dialogs/edit_project_dialog.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/create_project_dialog.dart';

/// Project List screen - Shows all projects
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      activeRoute: AppRouter.projectList,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Settings Button
          Tooltip(
            message: 'Daily Goal Settings',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Open settings dialog
              },
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
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
                    Text('All Projects', style: AppTextStyles.heading2),
                    SizedBox(height: AppConstants.spacing4),
                    Text(
                      'Manage and view all your projects',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                // Add New Project Button
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
            SizedBox(height: AppConstants.spacing32),

            // Projects List
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final columnCount = maxWidth > 1200
                    ? 3
                    : maxWidth > 800
                    ? 2
                    : 1;

                final projectsAsync = ref.watch(projectsProvider);

                return projectsAsync.when(
                  data: (projects) {
                    if (projects.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.spacing32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 64,
                                color: AppColors.brandPrimary,
                              ),
                              SizedBox(height: AppConstants.spacing16),
                              Text(
                                'No projects yet',
                                style: AppTextStyles.heading2,
                              ),
                              SizedBox(height: AppConstants.spacing8),
                              Text(
                                'Create your first project to get started!',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnCount,
                                childAspectRatio: 1.1,
                                mainAxisSpacing: AppConstants.spacing16,
                                crossAxisSpacing: AppConstants.spacing16,
                              ),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
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
                                      onEditPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => EditProjectDialog(
                                            projectId: project.id,
                                            initialName: project.name,
                                            initialDescription:
                                                project.description ?? '',
                                            initialEmoji: project.color ?? '📁',
                                            onSavePressed:
                                                (
                                                  projectId,
                                                  name,
                                                  description,
                                                  emoji,
                                                ) async {
                                                  try {
                                                    await ref.read(
                                                      updateProjectProvider(
                                                        UpdateProjectParams(
                                                          id: projectId,
                                                          name: name,
                                                          description:
                                                              description,
                                                          color: emoji,
                                                          status:
                                                              project.status,
                                                          createdAt:
                                                              project.createdAt,
                                                        ),
                                                      ).future,
                                                    );

                                                    ref.invalidate(
                                                      projectsProvider,
                                                    );

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Project "$name" updated!',
                                                          ),
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
                                                            'Error updating project: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                          ),
                                        );
                                      },
                                      onDeletePressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => ConfirmDeleteDialog(
                                            itemName: project.name,
                                            itemType: 'project',
                                            description:
                                                'All tasks in this project will also be deleted.',
                                            onConfirmPressed: () async {
                                              try {
                                                await ref.read(
                                                  deleteProjectProvider(
                                                    project.id,
                                                  ).future,
                                                );
                                                ref.invalidate(
                                                  projectsProvider,
                                                );

                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Project "${project.name}" deleted!',
                                                      ),
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
                                                        'Error deleting project: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
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
                                  final navigate = ref.read(navigateToProvider);
                                  navigate(
                                    AppRouter.projectDetail,
                                    projectId: project.id,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading projects: $err')),
                );
              },
            ),
          ],
        ),
      ),
    );
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
}
