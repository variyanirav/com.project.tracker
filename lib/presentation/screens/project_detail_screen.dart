import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/task_status.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/live_hours_overlay.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../utils/timer_session_actions.dart';
import '../widgets/dialogs/edit_task_dialog.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _debouncedSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    final currentText = _searchController.text;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _debouncedSearchQuery = currentText.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

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
        child: Center(
          child: Text(
            'No project found',
            style: AppTypography.body.copyWith(color: surface.textSecondary),
          ),
        ),
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
    final deletedTasksAsync = ref.watch(
      deletedTasksByProjectProvider(selectedProject.id),
    );
    final taskViewMode = switch (_taskView) {
      'archive' => ProjectTaskViewMode.archived,
      'trash' => ProjectTaskViewMode.trash,
      _ => ProjectTaskViewMode.active,
    };
    final useSearch = _debouncedSearchQuery.isNotEmpty;
    final searchedTasksAsync = useSearch
        ? ref.watch(
            searchedTasksByProjectProvider(
              ProjectTaskSearchParams(
                projectId: selectedProject.id,
                viewMode: taskViewMode,
                query: _debouncedSearchQuery,
              ),
            ),
          )
        : null;
    final timerState = ref.watch(timerProvider);
    final timerTickAsync = ref.watch(timerTickProvider);
    final hasActiveTimerForSelectedProject =
        timerState.isRunning && timerState.projectId == selectedProject.id;
    final taskViewTitle = switch (_taskView) {
      'archive' => 'Archived Tasks',
      'trash' => 'Trash',
      _ => AppStrings.screenTitles.projectTasks,
    };
    final hasSearchQuery = _debouncedSearchQuery.isNotEmpty;
    final emptyTitle = hasSearchQuery
        ? 'No tasks match your search'
        : switch (_taskView) {
            'archive' => 'No items in Archive',
            'trash' => 'No items in Trash',
            _ => AppStrings.messages.noRecordsFound,
          };
    final emptyMessage = hasSearchQuery
        ? 'Try a different keyword or clear the search to see every task.'
        : switch (_taskView) {
            'archive' =>
              'Archive completed tasks to keep them out of the main list.',
            'trash' =>
              'Restore deleted tasks from Trash or delete them permanently.',
            _ => AppStrings.messages.createFirstTaskInstructions,
          };

    late final Widget taskListWidget;

    Widget buildTaskList() {
      if (_taskView == 'active') {
        return (searchedTasksAsync ?? activeTasksAsync).when(
          data: (tasks) => TaskListView(
            tasks: tasks,
            timerRunningTaskId: timerState.taskId,
            isTimerRunning: timerState.isRunning,
            currentRunningElapsedSeconds: timerState.elapsedSeconds,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
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
                          AppStrings.messages.stopCurrentTimerWarning,
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }

                if (timerState.isRunning && timerState.taskId == task.id) {
                  await stopTimerWithOutcomeNote(context, ref);
                  await Future.delayed(const Duration(milliseconds: 100));
                  ref.invalidate(
                    activeTasksByProjectProvider(selectedProject.id),
                  );
                  ref.invalidate(
                    archivedTasksByProjectProvider(selectedProject.id),
                  );
                  ref.invalidate(projectTotalHoursProvider(selectedProject.id));
                  ref.invalidate(projectTodayHoursProvider(selectedProject.id));
                  ref.invalidate(projectWeekHoursProvider(selectedProject.id));
                  ref.invalidate(projectMonthHoursProvider(selectedProject.id));
                } else {
                  await ref
                      .read(timerProvider.notifier)
                      .startTimer(
                        task.id,
                        selectedProject.id,
                        startNote: await showTimerSessionNoteDialog(
                          context,
                          title: 'Session Plan',
                          hintText: 'What are you going to work on now?',
                        ),
                      );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.messages.timerOperationError('$e'),
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
                  initialEstimatedHours: task.estimatedHours,
                  initialIsBillable: task.isBillable,
                  initialStatus: TaskStatus.fromValue(task.status),
                  onSavePressed:
                      (
                        taskId,
                        categoryId,
                        title,
                        description,
                        estimatedHours,
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
                              estimatedHours: estimatedHours,
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
                          activeTasksByProjectProvider(selectedProject.id),
                        );
                      },
                ),
              );
            },
            onDeletePressed: (task) {
              showDialog(
                context: context,
                builder: (context) => AppConfirmationDialog(
                  title: 'Move to Trash',
                  message:
                      'Move "${task.taskName}" to Trash? You can restore it later from the Trash tab.',
                  confirmLabel: 'Move',
                  cancelLabel: 'Cancel',
                  icon: Icons.delete_outline,
                  iconColor: Colors.orange,
                  onConfirmPressed: () async {
                    await ref.read(
                      deleteTaskProvider(
                        DeleteTaskParams(
                          taskId: task.id,
                          projectId: selectedProject.id,
                        ),
                      ).future,
                    );
                  },
                ),
              );
            },
            onArchivePressed: (task) =>
                _archiveTask(context, ref, selectedProject.id, task),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              '${AppStrings.errors.loadingTasks}: $err',
              style: AppTypography.body.copyWith(color: surface.textSecondary),
            ),
          ),
        );
      }

      if (_taskView == 'archive') {
        return (searchedTasksAsync ?? archivedTasksAsync).when(
          data: (tasks) => TaskListView(
            tasks: tasks,
            timerRunningTaskId: null,
            isTimerRunning: false,
            currentRunningElapsedSeconds: 0,
            readOnly: true,
            showStatusFilters: false,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
            onViewPressed: (task) => _openTaskDetails(task, readOnly: true),
            onStartStopPressed: (_) {},
            onEditPressed: (_) {},
            onRestorePressed: (task) =>
                _restoreArchivedTask(context, ref, selectedProject.id, task),
            allowPermanentDeleteAction: false,
            onDeletePressed: (_) {},
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              '${AppStrings.errors.loadingTasks}: $err',
              style: AppTypography.body.copyWith(color: surface.textSecondary),
            ),
          ),
        );
      }

      return (searchedTasksAsync ?? deletedTasksAsync).when(
        data: (tasks) => TaskListView(
          tasks: tasks,
          timerRunningTaskId: null,
          isTimerRunning: false,
          currentRunningElapsedSeconds: 0,
          readOnly: true,
          showStatusFilters: false,
          emptyTitle: emptyTitle,
          emptyMessage: emptyMessage,
          onViewPressed: (task) => _openTaskDetails(task, readOnly: true),
          onStartStopPressed: (_) {},
          onEditPressed: (_) {},
          onDeletePressed: (task) =>
              _permanentlyDeleteTask(context, ref, selectedProject.id, task),
          onRestorePressed: (task) =>
              _restoreArchivedTask(context, ref, selectedProject.id, task),
          allowPermanentDeleteAction: true,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            '${AppStrings.errors.loadingTasks}: $err',
            style: AppTypography.body.copyWith(color: surface.textSecondary),
          ),
        ),
      );
    }

    taskListWidget = buildTaskList();

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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasActiveTimerForSelectedProject)
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
                              await stopTimerWithOutcomeNote(context, ref);
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
                        taskViewTitle,
                        style: AppTypography.sectionTitle.copyWith(
                          color: surface.textPrimary,
                        ),
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
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Trash'),
                        selected: _taskView == 'trash',
                        onSelected: (_) => setState(() => _taskView = 'trash'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface.panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: surface.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: surface.panelLowest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: surface.accentStrong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter this task list',
                                    style: AppTypography.label.copyWith(
                                      color: surface.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Search by task name, details, status, or deleted items in the selected view.',
                                    style: AppTypography.helper.copyWith(
                                      color: surface.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_debouncedSearchQuery.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: surface.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Live',
                                  style: AppTypography.helper.copyWith(
                                    color: surface.accentStrong,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText:
                                'Search within ${_taskView == 'active'
                                    ? 'Tasks'
                                    : _taskView == 'archive'
                                    ? 'Archive'
                                    : 'Trash'}...',
                            hintStyle: AppTypography.body.copyWith(
                              color: surface.textMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: surface.textSecondary,
                            ),
                            suffixIcon: _searchController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: surface.textSecondary,
                                    ),
                                    onPressed: () => _searchController.clear(),
                                  ),
                            filled: true,
                            fillColor: surface.panelLowest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: surface.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: surface.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: surface.accentStrong.withOpacity(0.5),
                                width: 1.2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        if (_debouncedSearchQuery.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Searching "$_debouncedSearchQuery" in ${_taskView == 'active'
                                ? 'Tasks'
                                : _taskView == 'archive'
                                ? 'Archive'
                                : 'Trash'}',
                            style: AppTypography.helper.copyWith(
                              color: surface.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  taskListWidget,
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
        onCreatePressed:
            (title, description, categoryId, estimatedHours, isBillable) async {
              await ref.read(
                createTaskProvider(
                  CreateTaskParams(
                    projectId: projectId,
                    categoryId: categoryId,
                    taskName: title,
                    description: description,
                    estimatedHours: estimatedHours,
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

  Future<void> _permanentlyDeleteTask(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    TaskEntity task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Delete Permanently',
        message:
            'Permanently delete "${task.taskName}"? This cannot be restored.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        icon: Icons.delete_forever,
        iconColor: Colors.red,
        onConfirmPressed: () async {
          await ref.read(
            permanentlyDeleteTaskProvider(
              DeleteTaskParams(taskId: task.id, projectId: projectId),
            ).future,
          );
        },
      ),
    );

    if (confirmed == true) {
      ref.invalidate(tasksByProjectProvider(projectId));
      ref.invalidate(activeTasksByProjectProvider(projectId));
      ref.invalidate(archivedTasksByProjectProvider(projectId));
      ref.invalidate(deletedTasksByProjectProvider(projectId));
    }
  }

  Future<void> _restoreArchivedTask(
    BuildContext context,
    WidgetRef ref,
    String projectId,
    TaskEntity task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Restore Task',
        message: 'Restore "${task.taskName}" from Trash?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        icon: Icons.restore_outlined,
        onConfirmPressed: () async {
          await ref.read(
            restoreDeletedTaskProvider(
              DeleteTaskParams(taskId: task.id, projectId: projectId),
            ).future,
          );
        },
      ),
    );

    if (confirmed == true) {
      ref.invalidate(activeTasksByProjectProvider(projectId));
      ref.invalidate(archivedTasksByProjectProvider(projectId));
      ref.invalidate(deletedTasksByProjectProvider(projectId));
    }
  }
}
