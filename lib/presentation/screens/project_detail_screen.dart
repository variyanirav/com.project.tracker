import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/task_status.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/edit_task_dialog.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/view_task_dialog.dart';
import '../widgets/project_detail/active_timer_card.dart';
import '../widgets/project_detail/create_task_form.dart';
import '../widgets/project_detail/empty_timer_state.dart';
import '../widgets/project_detail/project_header.dart';
import '../widgets/project_detail/stats_card.dart';
import '../widgets/project_detail/task_list_view.dart';
import '../widgets/project_detail/today_tasks_sidebar.dart';

/// Project Detail Screen
/// Shows project information, active timer, and task history
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, this.title = 'Project Detail'});

  final String title;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get selected project ID from navigation provider
    final selectedProjectId = ref.watch(selectedProjectIdProvider);

    // Fetch the selected project from database
    final projectsAsync = ref.watch(projectsProvider);
    final selectedProject = projectsAsync.whenData((projects) {
      if (selectedProjectId == null || selectedProjectId.isEmpty) {
        return projects.isNotEmpty ? projects.first : null;
      }
      try {
        return projects.firstWhere((p) => p.id == selectedProjectId);
      } catch (e) {
        return projects.isNotEmpty ? projects.first : null;
      }
    }).value;

    if (selectedProject == null) {
      return CustomScaffold(
        activeRoute: AppRouter.projectDetail,
        child: const Center(child: Text('No project found')),
      );
    }

    // Watch all required providers
    final projectHours = ref.watch(
      projectTotalHoursProvider(selectedProject.id),
    );
    final tasksAsync = ref.watch(tasksByProjectProvider(selectedProject.id));
    final timerState = ref.watch(timerProvider);
    final timerTickAsync = ref.watch(timerTickProvider);
    final hasActiveTimer = timerState.isRunning;

    return CustomScaffold(
      activeRoute: AppRouter.projectDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ProjectHeader(projectName: selectedProject.name),
            const SizedBox(height: 32),

            // Statistics Section
            Row(
              children: [
                // Total Hours
                Expanded(
                  child: projectHours.when(
                    data: (hours) => StatsCard(
                      title: AppStrings.labels.totalHours,
                      value: DateTimeFormatter.formatHours(hours),
                      icon: Icons.trending_up,
                      isDark: isDark,
                    ),
                    loading: () => StatsCard(
                      title: AppStrings.labels.totalHours,
                      value: 'Loading...',
                      icon: Icons.trending_up,
                      isDark: isDark,
                    ),
                    error: (err, stack) => StatsCard(
                      title: AppStrings.labels.totalHours,
                      value: 'Error',
                      icon: Icons.trending_up,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Today's Hours
                Expanded(
                  child: FutureBuilder<double>(
                    future: ref.watch(
                      projectTodayHoursProvider(selectedProject.id).future,
                    ),
                    builder: (context, snapshot) {
                      final todayHours = snapshot.data ?? 0.0;
                      return StatsCard(
                        title: AppStrings.labels.todayHours,
                        value:
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : DateTimeFormatter.formatHours(todayHours),
                        icon: Icons.today,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // This Week Hours
                Expanded(
                  child: FutureBuilder<double>(
                    future: ref.watch(
                      projectWeekHoursProvider(selectedProject.id).future,
                    ),
                    builder: (context, snapshot) {
                      final weekHours = snapshot.data ?? 0.0;
                      return StatsCard(
                        title: AppStrings.labels.thisWeek,
                        value:
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : DateTimeFormatter.formatHours(weekHours),
                        icon: Icons.calendar_today,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Content: Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Timer & Tasks
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timer Card
                      if (!hasActiveTimer)
                        EmptyTimerState(isDark: isDark)
                      else
                        FutureBuilder<TaskEntity?>(
                          future: ref.watch(activeTaskProvider.future),
                          builder: (context, snapshot) {
                            final activeTask = snapshot.data;
                            return ActiveTimerCard(
                              activeTask: activeTask,
                              timerState: timerState,
                              timerTickAsync: timerTickAsync,
                              isDark: isDark,
                              onPauseStartPressed: () async {
                                try {
                                  if (timerState.isPaused) {
                                    await ref
                                        .read(timerProvider.notifier)
                                        .resumeTimer();
                                  } else {
                                    await ref
                                        .read(timerProvider.notifier)
                                        .pauseTimer();
                                  }
                                  debugPrint(
                                    '[UI] Pause/Start button pressed successfully',
                                  );
                                } catch (e) {
                                  debugPrint('[UI] Pause/Start error: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppStrings.messages
                                              .timerOperationError('$e'),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              onStopPressed: () async {
                                try {
                                  await ref
                                      .read(timerProvider.notifier)
                                      .stopTimer();
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  ref.invalidate(
                                    tasksByProjectProvider(selectedProject.id),
                                  );
                                  ref.invalidate(
                                    projectTotalHoursProvider(
                                      selectedProject.id,
                                    ),
                                  );
                                  ref.invalidate(
                                    projectTodayHoursProvider(
                                      selectedProject.id,
                                    ),
                                  );
                                  ref.invalidate(
                                    projectWeekHoursProvider(
                                      selectedProject.id,
                                    ),
                                  );
                                  debugPrint(
                                    '[UI] Stop button pressed successfully',
                                  );
                                } catch (e) {
                                  debugPrint('[UI] Stop error: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppStrings.messages
                                              .timerOperationError('$e'),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 32),

                      // Create New Task Section
                      Text(
                        AppStrings.screenTitles.createNewTask,
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      CreateTaskForm(
                        onCreateTask: (title, description) async {
                          try {
                            await ref.read(
                              createTaskProvider(
                                CreateTaskParams(
                                  projectId: selectedProject.id,
                                  taskName: title,
                                  description: description,
                                ),
                              ).future,
                            );

                            ref.invalidate(
                              tasksByProjectProvider(selectedProject.id),
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.messages.taskCreatedSuccess(
                                      title,
                                    ),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.messages.taskCreationError('$e'),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Project Tasks Section
                      Text(
                        AppStrings.screenTitles.projectTasks,
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      tasksAsync.when(
                        data: (tasks) => TaskListView(
                          tasks: tasks,
                          timerRunningTaskId: timerState.taskId,
                          isTimerRunning: timerState.isRunning,
                          currentRunningElapsedSeconds:
                              timerState.elapsedSeconds,
                          onViewPressed: (task) {
                            showDialog(
                              context: context,
                              builder: (context) => ViewTaskDialog(task: task),
                            );
                          },
                          onStartStopPressed: (task) async {
                            try {
                              // Check if timer is already running for a different task
                              if (!task.isRunning &&
                                  timerState.isRunning &&
                                  timerState.taskId != task.id) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppStrings
                                            .messages
                                            .stopCurrentTimerWarning,
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Use real-time timerState for accurate status
                              if (timerState.isRunning &&
                                  timerState.taskId == task.id) {
                                // Stop timer
                                debugPrint(
                                  '[UI] Stop button clicked for task: ${task.id}',
                                );
                                await ref
                                    .read(timerProvider.notifier)
                                    .stopTimer();
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                ref.invalidate(
                                  tasksByProjectProvider(selectedProject.id),
                                );
                                ref.invalidate(
                                  projectTotalHoursProvider(selectedProject.id),
                                );
                                ref.invalidate(
                                  projectTodayHoursProvider(selectedProject.id),
                                );
                                ref.invalidate(
                                  projectWeekHoursProvider(selectedProject.id),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppStrings.messages.timerStoppedSuccess(
                                          task.taskName,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                // Start timer
                                debugPrint(
                                  '[UI] Start button clicked for task: ${task.id}',
                                );
                                await ref
                                    .read(timerProvider.notifier)
                                    .startTimer(task.id, selectedProject.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppStrings.messages.timerStartedSuccess(
                                          task.taskName,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppStrings.messages.timerOperationError(
                                        '$e',
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onEditPressed: (task) {
                            showDialog(
                              context: context,
                              builder: (context) => EditTaskDialog(
                                taskId: task.id,
                                initialTitle: task.taskName,
                                initialDescription: task.description ?? '',
                                initialStatus: TaskStatus.values.firstWhere(
                                  (s) => s.label == task.status,
                                  orElse: () => TaskStatus.todo,
                                ),
                                onSavePressed:
                                    (taskId, title, description, status) async {
                                      try {
                                        await ref.read(
                                          updateTaskProvider(
                                            UpdateTaskParams(
                                              id: taskId,
                                              projectId: selectedProject.id,
                                              taskName: title,
                                              description: description,
                                              status: status.label,
                                              totalSeconds: task.totalSeconds,
                                              isRunning: task.isRunning,
                                              createdAt: task.createdAt,
                                              lastStartedAt: task.lastStartedAt,
                                              lastSessionId: task.lastSessionId,
                                            ),
                                          ).future,
                                        );

                                        ref.invalidate(
                                          tasksByProjectProvider(
                                            selectedProject.id,
                                          ),
                                        );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppStrings.messages
                                                    .taskUpdatedSuccess(title),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
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
                                                AppStrings.messages
                                                    .taskUpdateError('$e'),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              ),
                            );
                          },
                          onDeletePressed: (task) {
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmDeleteDialog(
                                itemName: task.taskName,
                                itemType: 'task',
                                onConfirmPressed: () async {
                                  try {
                                    await ref.read(
                                      deleteTaskProvider(
                                        DeleteTaskParams(
                                          taskId: task.id,
                                          projectId: selectedProject.id,
                                        ),
                                      ).future,
                                    );

                                    ref.invalidate(
                                      tasksByProjectProvider(
                                        selectedProject.id,
                                      ),
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppStrings
                                                .messages
                                                .taskDeletedSuccess,
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppStrings.messages
                                                .taskDeletionError('$e'),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text(
                            '${AppStrings.errors.loadingTasks}: $err',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right: Today's Tasks Sidebar
                Expanded(
                  flex: 1,
                  child: tasksAsync.when(
                    data: (allTasks) {
                      final today = DateTime.now();
                      final todaysTasks = allTasks.where((task) {
                        final taskDate = task.createdAt;
                        return taskDate.year == today.year &&
                            taskDate.month == today.month &&
                            taskDate.day == today.day;
                      }).toList();

                      return TodayTasksSidebar(todaysTasks: todaysTasks);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text(
                        '${AppStrings.errors.loadingData}: $err',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
