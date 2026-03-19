import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/theme/text_styles.dart';
import '../providers/theme_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dashboard/project_card.dart' show ProjectCard, RecentTask;
import '../widgets/dialogs/edit_project_dialog.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';

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

                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        childAspectRatio: 1.1,
                        mainAxisSpacing: AppConstants.spacing16,
                        crossAxisSpacing: AppConstants.spacing16,
                      ),
                      itemCount: 6, // Sample data
                      itemBuilder: (context, index) {
                        final projects = [
                          {
                            'title': 'Mobile App Redesign',
                            'description': 'Refresh the user interface and UX',
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
                              RecentTask(name: 'Color tokens', status: 'To Do'),
                              RecentTask(
                                name: 'Typography system',
                                status: 'In Progress',
                              ),
                            ],
                          },
                          {
                            'title': 'Marketing Website',
                            'description': 'Company landing page redesign',
                            'emoji': '🌐',
                            'hours': '15h 20m',
                            'tasks': [
                              RecentTask(
                                name: 'Homepage layout',
                                status: 'In Progress',
                              ),
                              RecentTask(
                                name: 'SEO optimization',
                                status: 'To Do',
                              ),
                            ],
                          },
                          {
                            'title': 'Mobile Testing',
                            'description':
                                'Cross-platform compatibility testing',
                            'emoji': '📲',
                            'hours': '6h 40m',
                            'tasks': [
                              RecentTask(
                                name: 'iOS testing',
                                status: 'Complete',
                              ),
                              RecentTask(
                                name: 'Android testing',
                                status: 'In Progress',
                              ),
                            ],
                          },
                          {
                            'title': 'Documentation',
                            'description': 'API and code documentation',
                            'emoji': '📚',
                            'hours': '4h 10m',
                            'tasks': [
                              RecentTask(
                                name: 'API docs',
                                status: 'In Progress',
                              ),
                              RecentTask(
                                name: 'Code examples',
                                status: 'To Do',
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
                            ref.read(currentScreenProvider.notifier).state =
                                AppRouter.projectDetail;
                          },
                          onEditPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditProjectDialog(
                                projectId: 'project_${index + 1}',
                                initialName: project['title'] as String,
                                initialDescription:
                                    project['description'] as String,
                                initialEmoji: project['emoji'] as String,
                                onSavePressed:
                                    (projectId, name, description, emoji) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Project "$name" updated!',
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            );
                          },
                          onDeletePressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmDeleteDialog(
                                itemName: project['title'] as String,
                                itemType: 'project',
                                description:
                                    'All tasks in this project will also be deleted.',
                                onConfirmPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Project "${project['title']}" deleted!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
