import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/task_status.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/app_card.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/edit_task_dialog.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/view_task_dialog.dart';

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
  late TextEditingController _taskTitleController;
  late TextEditingController _taskDescriptionController;
  TaskStatus _selectedStatus = TaskStatus.todo;
  int _currentTaskPage = 0;
  final int _tasksPerPage = 20;

  @override
  void initState() {
    super.initState();
    _taskTitleController = TextEditingController();
    _taskDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
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
      // Find project by ID
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

    final projectHours = ref.watch(
      projectTotalHoursProvider(selectedProject.id),
    );
    final tasksAsync = ref.watch(tasksByProjectProvider(selectedProject.id));
    final timerState = ref.watch(timerProvider);
    final hasActiveTimer = timerState.isRunning;

    return CustomScaffold(
      activeRoute: AppRouter.projectDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project Details', style: AppTextStyles.heading1),
                    const SizedBox(height: 4),
                    Text(selectedProject.name, style: AppTextStyles.bodyMedium),
                  ],
                ),
                AppAvatar(
                  initials: selectedProject.name.isEmpty
                      ? 'P'
                      : selectedProject.name[0].toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Time Statistics Cards
            Row(
              children: [
                Expanded(
                  child: projectHours.when(
                    data: (hours) => _StatCard(
                      title: 'Total Hours',
                      value: _formatHours(hours),
                      icon: Icons.trending_up,
                      isDark: isDark,
                    ),
                    loading: () => _StatCard(
                      title: 'Total Hours',
                      value: 'Loading...',
                      icon: Icons.trending_up,
                      isDark: isDark,
                    ),
                    error: (err, stack) => _StatCard(
                      title: 'Total Hours',
                      value: 'Error',
                      icon: Icons.trending_up,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<double>(
                    future: ref.watch(
                      projectTodayHoursProvider(selectedProject.id).future,
                    ),
                    builder: (context, snapshot) {
                      final todayHours = snapshot.data ?? 0.0;
                      return _StatCard(
                        title: 'Today\'s Hours',
                        value:
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : _formatHours(todayHours),
                        icon: Icons.today,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<double>(
                    future: ref.watch(
                      projectWeekHoursProvider(selectedProject.id).future,
                    ),
                    builder: (context, snapshot) {
                      final weekHours = snapshot.data ?? 0.0;
                      return _StatCard(
                        title: 'This Week',
                        value:
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : _formatHours(weekHours),
                        icon: Icons.calendar_today,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main content: Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Active Task & Timer
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Task Card
                      if (!hasActiveTimer)
                        AppCard(
                          padding: const EdgeInsets.all(24),
                          backgroundColor: isDark
                              ? Colors.grey[900]
                              : Colors.grey[50],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 48,
                                  color: AppColors.brandPrimary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Active Timer',
                                  style: AppTextStyles.heading2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a timer on any task below to begin tracking',
                                  style: AppTextStyles.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        AppCard(
                          padding: const EdgeInsets.all(24),
                          backgroundColor: isDark
                              ? Colors.grey[900]
                              : Colors.grey[50],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currently Tracking',
                                style: AppTextStyles.labelMedium,
                              ),
                              const SizedBox(height: 16),
                              // Show active task details from provider
                              FutureBuilder<TaskEntity?>(
                                future: ref.watch(activeTaskProvider.future),
                                builder: (context, snapshot) {
                                  final activeTask = snapshot.data;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeTask?.taskName ?? 'Task',
                                        style: AppTextStyles.heading2,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            activeTask?.description ??
                                                'In Progress',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: TaskStatus.inProgress
                                                  .getColor()
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'In Progress',
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                    color: TaskStatus.inProgress
                                                        .getColor(),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Timer Display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _formatElapsedTime(
                                      timerState.elapsedSeconds,
                                    ),
                                    style: AppTextStyles.timerDisplay.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Control Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton.primary(
                                      label: 'Pause',
                                      onPressed: () {
                                        ref
                                            .read(timerProvider.notifier)
                                            .pauseTimer();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton.danger(
                                      label: 'Stop',
                                      onPressed: () async {
                                        await ref
                                            .read(timerProvider.notifier)
                                            .stopTimer();
                                        // Invalidate task data to refresh totals
                                        ref.invalidate(
                                          tasksByProjectProvider(
                                            selectedProject.id,
                                          ),
                                        );
                                        ref.invalidate(
                                          projectTotalHoursProvider(
                                            selectedProject.id,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Start New Task Section
                      Text('Create New Task', style: AppTextStyles.heading2),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title
                            TextField(
                              controller: _taskTitleController,
                              decoration: InputDecoration(
                                labelText: 'Task Title',
                                hintText: 'Enter task title...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            TextField(
                              controller: _taskDescriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Add task details...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: AppButton.primary(
                                label: 'Create Task',
                                onPressed: () async {
                                  if (_taskTitleController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a task title',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    await ref.read(
                                      createTaskProvider(
                                        CreateTaskParams(
                                          projectId: selectedProject.id,
                                          taskName: _taskTitleController.text,
                                          description:
                                              _taskDescriptionController
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : _taskDescriptionController.text,
                                        ),
                                      ).future,
                                    );

                                    // Invalidate task list to refresh
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
                                            'Task "${_taskTitleController.text}" created!',
                                          ),
                                        ),
                                      );
                                      // Clear fields after creation
                                      _taskTitleController.clear();
                                      _taskDescriptionController.clear();
                                      setState(() {
                                        _selectedStatus = TaskStatus.todo;
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error creating task: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // All Tasks Section
                      Text('Project Tasks', style: AppTextStyles.heading2),
                      const SizedBox(height: 16),
                      tasksAsync.when(
                        data: (tasks) {
                          if (tasks.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.task_outlined,
                                      size: 48,
                                      color: AppColors.brandPrimary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tasks yet',
                                      style: AppTextStyles.heading2,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first task above',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Take paginated tasks
                          final start = _currentTaskPage * _tasksPerPage;
                          final end = (start + _tasksPerPage).clamp(
                            0,
                            tasks.length,
                          );
                          final paginatedTasks = tasks.sublist(start, end);

                          return Column(
                            children: [
                              ...paginatedTasks.map((task) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header: Title & Status
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                task.taskName,
                                                style:
                                                    AppTextStyles.labelMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: TaskStatus.values
                                                    .firstWhere(
                                                      (s) =>
                                                          s.label ==
                                                          task.status,
                                                      orElse: () =>
                                                          TaskStatus.todo,
                                                    )
                                                    .getColor()
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                task.status,
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                      color: TaskStatus.values
                                                          .firstWhere(
                                                            (s) =>
                                                                s.label ==
                                                                task.status,
                                                            orElse: () =>
                                                                TaskStatus.todo,
                                                          )
                                                          .getColor(),
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Metadata: Duration & Date
                                        Text(
                                          '${_formatSeconds(task.totalSeconds)} · ${_formatDate(task.createdAt)}',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                        const SizedBox(height: 16),

                                        // Action Buttons Row
                                        Row(
                                          children: [
                                            // View Button
                                            Tooltip(
                                              message: 'View task details',
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.purple
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.purple
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            ViewTaskDialog(
                                                              task: task,
                                                            ),
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      child: Icon(
                                                        Icons.info_outline,
                                                        size: 18,
                                                        color: Colors.purple,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Start/Stop Timer Button
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      (task.isRunning
                                                              ? Colors.orange
                                                              : Colors.green)
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        (task.isRunning
                                                                ? Colors.orange
                                                                : Colors.green)
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      try {
                                                        if (task.isRunning) {
                                                          // Stop the timer
                                                          await ref
                                                              .read(
                                                                timerProvider
                                                                    .notifier,
                                                              )
                                                              .stopTimer();
                                                          // Don't invalidate immediately - let the timer state change reflect in the UI
                                                          // A small delay allows the database to update before next refresh
                                                          await Future.delayed(
                                                            const Duration(
                                                              milliseconds: 100,
                                                            ),
                                                          );
                                                          ref.invalidate(
                                                            tasksByProjectProvider(
                                                              selectedProject
                                                                  .id,
                                                            ),
                                                          );
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Timer stopped for "${task.taskName}"',
                                                                ),
                                                                duration:
                                                                    const Duration(
                                                                      seconds:
                                                                          2,
                                                                    ),
                                                              ),
                                                            );
                                                          }
                                                        } else {
                                                          // Start the timer
                                                          await ref
                                                              .read(
                                                                timerProvider
                                                                    .notifier,
                                                              )
                                                              .startTimer(
                                                                task.id,
                                                                selectedProject
                                                                    .id,
                                                              );
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Timer started for "${task.taskName}"',
                                                                ),
                                                                duration:
                                                                    const Duration(
                                                                      seconds:
                                                                          2,
                                                                    ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Error: $e',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                            horizontal: 12,
                                                          ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            task.isRunning
                                                                ? Icons.stop
                                                                : Icons
                                                                      .play_arrow,
                                                            size: 18,
                                                            color:
                                                                task.isRunning
                                                                ? Colors.orange
                                                                : Colors.green,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            task.isRunning
                                                                ? 'Stop'
                                                                : 'Start',
                                                            style: AppTextStyles
                                                                .labelSmall
                                                                .copyWith(
                                                                  color:
                                                                      task.isRunning
                                                                      ? Colors
                                                                            .orange
                                                                      : Colors
                                                                            .green,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Edit Button
                                            Tooltip(
                                              message: 'Edit task',
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => EditTaskDialog(
                                                          taskId: task.id,
                                                          initialTitle:
                                                              task.taskName,
                                                          initialDescription:
                                                              task.description ??
                                                              '',
                                                          initialStatus: TaskStatus
                                                              .values
                                                              .firstWhere(
                                                                (s) =>
                                                                    s.label ==
                                                                    task.status,
                                                                orElse: () =>
                                                                    TaskStatus
                                                                        .todo,
                                                              ),
                                                          onSavePressed:
                                                              (
                                                                taskId,
                                                                title,
                                                                description,
                                                                status,
                                                              ) async {
                                                                try {
                                                                  await ref.read(
                                                                    updateTaskProvider(
                                                                      UpdateTaskParams(
                                                                        id: taskId,
                                                                        projectId:
                                                                            selectedProject.id,
                                                                        taskName:
                                                                            title,
                                                                        description:
                                                                            description,
                                                                        status:
                                                                            status.label,
                                                                        totalSeconds:
                                                                            task.totalSeconds,
                                                                        isRunning:
                                                                            task.isRunning,
                                                                        createdAt:
                                                                            task.createdAt,
                                                                        lastStartedAt:
                                                                            task.lastStartedAt,
                                                                        lastSessionId:
                                                                            task.lastSessionId,
                                                                      ),
                                                                    ).future,
                                                                  );

                                                                  ref.invalidate(
                                                                    tasksByProjectProvider(
                                                                      selectedProject
                                                                          .id,
                                                                    ),
                                                                  );

                                                                  if (context
                                                                      .mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              'Task "$title"updated!',
                                                                            ),
                                                                        duration: const Duration(
                                                                          seconds:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                    );
                                                                    Navigator.pop(
                                                                      context,
                                                                    );
                                                                  }
                                                                } catch (e) {
                                                                  if (context
                                                                      .mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              'Error: $e',
                                                                            ),
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                        ),
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      child: Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Delete Button
                                            Tooltip(
                                              message: 'Delete task',
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => ConfirmDeleteDialog(
                                                          itemName:
                                                              task.taskName,
                                                          itemType: 'task',
                                                          onConfirmPressed: () async {
                                                            try {
                                                              await ref.read(
                                                                deleteTaskProvider(
                                                                  DeleteTaskParams(
                                                                    taskId:
                                                                        task.id,
                                                                    projectId:
                                                                        selectedProject
                                                                            .id,
                                                                  ),
                                                                ).future,
                                                              );

                                                              ref.invalidate(
                                                                tasksByProjectProvider(
                                                                  selectedProject
                                                                      .id,
                                                                ),
                                                              );

                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Task "${task.taskName}"deleted!',
                                                                    ),
                                                                    duration:
                                                                        const Duration(
                                                                          seconds:
                                                                              2,
                                                                        ),
                                                                  ),
                                                                );
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                              }
                                                            } catch (e) {
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Error: $e',
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      child: Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 16),
                              // Pagination Controls
                              if (tasks.length > _tasksPerPage)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppButton.secondary(
                                      label: 'Previous',
                                      onPressed: _currentTaskPage > 0
                                          ? () {
                                              setState(() {
                                                _currentTaskPage--;
                                              });
                                            }
                                          : null,
                                    ),
                                    Text(
                                      'Page ${_currentTaskPage + 1} of ${(tasks.length / _tasksPerPage).ceil()}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    AppButton.secondary(
                                      label: 'Next',
                                      onPressed:
                                          ((_currentTaskPage + 1) *
                                                  _tasksPerPage <
                                              tasks.length)
                                          ? () {
                                              setState(() {
                                                _currentTaskPage++;
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error loading tasks: $err',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right: Today's Tasks
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Tasks', style: AppTextStyles.heading2),
                      const SizedBox(height: 16),
                      tasksAsync.when(
                        data: (allTasks) {
                          // Filter tasks created today
                          final today = DateTime.now();
                          final todaysTasks = allTasks.where((task) {
                            final taskDate = task.createdAt;
                            return taskDate.year == today.year &&
                                taskDate.month == today.month &&
                                taskDate.day == today.day;
                          }).toList();

                          if (todaysTasks.isEmpty) {
                            return AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No tasks created today',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFA0AEC0),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: todaysTasks
                                .map(
                                  (task) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: AppCard(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  task.taskName,
                                                  style:
                                                      AppTextStyles.labelMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatSeconds(
                                                  task.totalSeconds,
                                                ),
                                                style: AppTextStyles.bodySmall,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: TaskStatus.values
                                                      .firstWhere(
                                                        (s) =>
                                                            s.label ==
                                                            task.status,
                                                        orElse: () =>
                                                            TaskStatus.todo,
                                                      )
                                                      .getColor()
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  task.status,
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                        color: TaskStatus.values
                                                            .firstWhere(
                                                              (s) =>
                                                                  s.label ==
                                                                  task.status,
                                                              orElse: () =>
                                                                  TaskStatus
                                                                      .todo,
                                                            )
                                                            .getColor(),
                                                        fontSize: 9,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error: $err',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ),
                    ],
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

  /// Format elapsed time in seconds to HH:MM:SS format
  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format seconds to readable format like "2h 30m"
  String _formatSeconds(int seconds) {
    if (seconds == 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  /// Format date to readable format like "20th Mar 2026"
  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day;
    final monthName = months[date.month];
    final year = date.year;
    final suffix = _getDayOfMonthSuffix(day);
    return '$day$suffix $monthName $year';
  }

  /// Get day of month suffix (st, nd, rd, th)
  String _getDayOfMonthSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.labelMedium),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: AppColors.brandPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.headingLarge),
        ],
      ),
    );
  }
}
