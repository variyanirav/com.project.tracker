import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/task_status.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/live_hours_overlay.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/edit_task_dialog.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/create_task_dialog.dart';
import '../../core/widgets/app_confirmation_dialog.dart';
import '../widgets/dialogs/timer_session_note_dialog.dart';
import '../widgets/dialogs/view_task_dialog.dart';
import '../widgets/project_detail/active_timer_card.dart';
import '../widgets/project_detail/empty_timer_state.dart';
import '../widgets/project_detail/project_header.dart';
import '../widgets/project_detail/stats_card.dart';
import '../widgets/project_detail/task_list_view.dart';

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
  String _taskView = 'active';

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
    final projectTotalHours = ref.watch(
      projectTotalHoursProvider(selectedProject.id),
    );
    final projectTodayHours = ref.watch(
      projectTodayHoursProvider(selectedProject.id),
    );
    final projectWeekHours = ref.watch(
      projectWeekHoursProvider(selectedProject.id),
    );
    final projectMonthHours = ref.watch(
      projectMonthHoursProvider(selectedProject.id),
    );
    final activeTasksAsync = ref.watch(
      activeTasksByProjectProvider(selectedProject.id),
    );
    final archivedTasksAsync = ref.watch(
      archivedTasksByProjectProvider(selectedProject.id),
    );
    final timerState = ref.watch(timerProvider);
    final timerTickAsync = ref.watch(timerTickProvider);
    final hasActiveTimer = timerState.isRunning;

    return CustomScaffold(
      activeRoute: AppRouter.projectDetail,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ProjectHeader(
              projectName: selectedProject.name,
              onCreatePressed: () =>
                  _openCreateTaskDialog(context, ref, selectedProject.id),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: projectTotalHours.when(
                    data: (hours) {
                      final liveTotalHours = LiveHoursOverlay.withLiveOverlay(
                        persistedHours: hours,
                        isTimerRunning: timerState.isRunning,
                        elapsedSeconds: timerState.elapsedSeconds,
                        timerStartTime: timerState.startTime,
                        timerProjectId: timerState.projectId,
                        scope: LiveHoursScope.project,
                        targetProjectId: selectedProject.id,
                      );

                      return StatsCard(
                        title: AppStrings.labels.totalHours,
                        value: DateTimeFormatter.formatHours(liveTotalHours),
                        icon: Icons.trending_up,
                        isDark: isDark,
                      );
                    },
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
                Expanded(
                  child: projectTodayHours.when(
                    data: (hours) => StatsCard(
                      title: AppStrings.labels.todayHours,
                      value: DateTimeFormatter.formatHours(hours),
                      icon: Icons.today,
                      isDark: isDark,
                    ),
                    loading: () => StatsCard(
                      title: AppStrings.labels.todayHours,
                      value: 'Loading...',
                      icon: Icons.today,
                      isDark: isDark,
                    ),
                    error: (err, stack) => StatsCard(
                      title: AppStrings.labels.todayHours,
                      value: 'Error',
                      icon: Icons.today,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: projectWeekHours.when(
                    data: (hours) => StatsCard(
                      title: AppStrings.labels.thisWeek,
                      value: DateTimeFormatter.formatHours(hours),
                      icon: Icons.calendar_view_week,
                      isDark: isDark,
                    ),
                    loading: () => StatsCard(
                      title: AppStrings.labels.thisWeek,
                      value: 'Loading...',
                      icon: Icons.calendar_view_week,
                      isDark: isDark,
                    ),
                    error: (err, stack) => StatsCard(
                      title: AppStrings.labels.thisWeek,
                      value: 'Error',
                      icon: Icons.calendar_view_week,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: projectMonthHours.when(
                    data: (hours) => StatsCard(
                      title: 'This Month',
                      value: DateTimeFormatter.formatHours(hours),
                      icon: Icons.calendar_month,
                      isDark: isDark,
                    ),
                    loading: () => StatsCard(
                      title: 'This Month',
                      value: 'Loading...',
                      icon: Icons.calendar_month,
                      isDark: isDark,
                    ),
                    error: (err, stack) => StatsCard(
                      title: 'This Month',
                      value: 'Error',
                      icon: Icons.calendar_month,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          onStopPressed: () async {
                            try {
                              final stopNote = await showTimerSessionNoteDialog(
                                context,
                                title: 'Session Outcome',
                                hintText:
                                    'What did you complete in this session?',
                              );
                              await ref
                                  .read(timerProvider.notifier)
                                  .stopTimer(stopNote: stopNote);
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
                              ref.invalidate(
                                projectMonthHoursProvider(selectedProject.id),
                              );
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
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        _taskView == 'active'
                            ? AppStrings.screenTitles.projectTasks
                            : 'Archived Tasks',
                        style: AppTextStyles.heading2,
                      ),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('Tasks'),
                        selected: _taskView == 'active',
                        onSelected: (_) => setState(() => _taskView = 'active'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Archive'),
                        selected: _taskView == 'archive',
                        onSelected: (_) =>
                            setState(() => _taskView = 'archive'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_taskView == 'active')
                    activeTasksAsync.when(
                      data: (tasks) => TaskListView(
                        tasks: tasks,
                        timerRunningTaskId: timerState.taskId,
                        isTimerRunning: timerState.isRunning,
                        currentRunningElapsedSeconds: timerState.elapsedSeconds,
                        onViewPressed: (task) => _openTaskDetails(task),
                        onStartStopPressed: (task) async {
                          try {
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

                            if (timerState.isRunning &&
                                timerState.taskId == task.id) {
                              await ref
                                  .read(timerProvider.notifier)
                                  .stopTimer(
                                    stopNote: await showTimerSessionNoteDialog(
                                      context,
                                      title: 'Session Outcome',
                                      hintText:
                                          'What did you complete in this session?',
                                    ),
                                  );
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              ref.invalidate(
                                activeTasksByProjectProvider(
                                  selectedProject.id,
                                ),
                              );
                              ref.invalidate(
                                archivedTasksByProjectProvider(
                                  selectedProject.id,
                                ),
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
                              ref.invalidate(
                                projectMonthHoursProvider(selectedProject.id),
                              );
                            } else {
                              await ref
                                  .read(timerProvider.notifier)
                                  .startTimer(
                                    task.id,
                                    selectedProject.id,
                                    startNote: await showTimerSessionNoteDialog(
                                      context,
                                      title: 'Session Plan',
                                      hintText:
                                          'What are you going to work on now?',
                                    ),
                                  );
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
                              initialCategoryId: task.categoryId,
                              initialTitle: task.taskName,
                              initialDescription: task.description ?? '',
                              initialIsBillable: task.isBillable,
                              initialStatus: TaskStatus.fromValue(task.status),
                              onSavePressed:
                                  (
                                    taskId,
                                    categoryId,
                                    title,
                                    description,
                                    status,
                                    isBillable,
                                  ) async {
                                    await ref.read(
                                      updateTaskProvider(
                                        UpdateTaskParams(
                                          id: taskId,
                                          projectId: selectedProject.id,
                                          categoryId: categoryId,
                                          taskName: title,
                                          description: description,
                                          status: status.code,
                                          isBillable: isBillable,
                                          totalSeconds: task.totalSeconds,
                                          isRunning: task.isRunning,
                                          createdAt: task.createdAt,
                                          lastStartedAt: task.lastStartedAt,
                                          lastSessionId: task.lastSessionId,
                                        ),
                                      ).future,
                                    );
                                    ref.invalidate(
                                      activeTasksByProjectProvider(
                                        selectedProject.id,
                                      ),
                                    );
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
                                await ref.read(
                                  deleteTaskProvider(
                                    DeleteTaskParams(
                                      taskId: task.id,
                                      projectId: selectedProject.id,
                                    ),
                                  ).future,
                                );
                                ref.invalidate(
                                  activeTasksByProjectProvider(
                                    selectedProject.id,
                                  ),
                                );
                                ref.invalidate(
                                  archivedTasksByProjectProvider(
                                    selectedProject.id,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        onArchivePressed: (task) => _archiveTask(
                          context,
                          ref,
                          selectedProject.id,
                          task,
                        ),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Text(
                          '${AppStrings.errors.loadingTasks}: $err',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    )
                  else
                    archivedTasksAsync.when(
                      data: (tasks) => TaskListView(
                        tasks: tasks,
                        timerRunningTaskId: null,
                        isTimerRunning: false,
                        currentRunningElapsedSeconds: 0,
                        readOnly: true,
                        showStatusFilters: false,
                        emptyTitle: 'No archived tasks',
                        emptyMessage:
                            'Archive completed tasks to keep them out of the main list.',
                        onViewPressed: (task) =>
                            _openTaskDetails(task, readOnly: true),
                        onStartStopPressed: (_) {},
                        onEditPressed: (_) {},
                        onDeletePressed: (_) {},
                        onRestorePressed: (task) => _restoreTask(
                          context,
                          ref,
                          selectedProject.id,
                          task,
                        ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateTaskDialog(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CreateTaskDialog(
        onCreatePressed: (title, description, categoryId, isBillable) async {
          await ref.read(
            createTaskProvider(
              CreateTaskParams(
                projectId: projectId,
                categoryId: categoryId,
                taskName: title,
                description: description,
                isBillable: isBillable,
              ),
            ).future,
          );
        },
      ),
    );

    if (created == true) {
      ref.invalidate(tasksByProjectProvider(projectId));
      ref.invalidate(activeTasksByProjectProvider(projectId));
      ref.invalidate(archivedTasksByProjectProvider(projectId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      }
    }
  }

  void _openTaskDetails(TaskEntity task, {bool readOnly = false}) {
    showDialog(
      context: context,
      builder: (context) => ViewTaskDialog(task: task, readOnly: readOnly),
    );
  }

  Future<void> _archiveTask(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    TaskEntity task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Archive Task',
        message:
            'Archive "${task.taskName}"? It will move to Archive and will not be editable or startable.',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        icon: Icons.archive_outlined,
        onConfirmPressed: () async {
          await ref.read(
            archiveTaskProvider(
              ArchiveTaskParams(taskId: task.id, projectId: projectId),
            ).future,
          );
        },
      ),
    );

    if (confirmed == true) {
      ref.invalidate(activeTasksByProjectProvider(projectId));
      ref.invalidate(archivedTasksByProjectProvider(projectId));
    }
  }

  Future<void> _restoreTask(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    TaskEntity task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Restore Task',
        message: 'Restore "${task.taskName}" back to completed tasks?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        icon: Icons.unarchive_outlined,
        onConfirmPressed: () async {
          await ref.read(
            unarchiveTaskProvider(
              ArchiveTaskParams(taskId: task.id, projectId: projectId),
            ).future,
          );
        },
      ),
    );

    if (confirmed == true) {
      ref.invalidate(activeTasksByProjectProvider(projectId));
      ref.invalidate(archivedTasksByProjectProvider(projectId));
    }
  }
}
