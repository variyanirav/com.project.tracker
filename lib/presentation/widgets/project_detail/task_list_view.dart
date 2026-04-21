import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../presentation/providers/category_provider.dart';
import 'empty_tasks_state.dart';

/// Displays project tasks in a card layout inspired by the todo list screen.
class TaskListView extends ConsumerStatefulWidget {
  final List<TaskEntity> tasks;
  final String? timerRunningTaskId;
  final bool isTimerRunning;
  final int currentRunningElapsedSeconds;
  final Function(TaskEntity task) onViewPressed;
  final Function(TaskEntity task) onStartStopPressed;
  final Function(TaskEntity task) onEditPressed;
  final Function(TaskEntity task) onDeletePressed;
  final Function(TaskEntity task)? onArchivePressed;
  final Function(TaskEntity task)? onRestorePressed;
  final bool readOnly;
  final bool showStatusFilters;
  final String emptyTitle;
  final String emptyMessage;
  final int tasksPerPage;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.timerRunningTaskId,
    required this.isTimerRunning,
    required this.currentRunningElapsedSeconds,
    required this.onViewPressed,
    required this.onStartStopPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
    this.onArchivePressed,
    this.onRestorePressed,
    this.readOnly = false,
    this.showStatusFilters = true,
    this.emptyTitle = 'No records found',
    this.emptyMessage = 'Try changing the status filter or rows selection.',
    this.tasksPerPage = 20,
  });

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  int _currentPage = 0;
  String _statusFilter = 'all';
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.tasksPerPage;
  }

  List<TaskEntity> get _filteredTasks {
    if (!widget.showStatusFilters || _statusFilter == 'all') {
      return widget.tasks;
    }

    return widget.tasks.where((task) {
      return TaskStatus.fromValue(task.status).code == _statusFilter;
    }).toList();
  }

  List<TaskEntity> get _paginatedTasks {
    final filtered = _filteredTasks;
    if (_pageSize == -1) {
      return filtered;
    }

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    if (start >= filtered.length) {
      return const <TaskEntity>[];
    }
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const EmptyTasksState();
    }

    final categoriesAsync = ref.watch(categoriesProvider);
    final filteredTasks = _filteredTasks;
    final visibleTasks = _paginatedTasks;

    final pageSize = _pageSize == -1 ? filteredTasks.length : _pageSize;
    final safePageSize = pageSize == 0 ? 1 : pageSize;
    final totalPages = filteredTasks.isEmpty
        ? 1
        : (filteredTasks.length / safePageSize).ceil();

    final canGoPrevious = _pageSize != -1 && _currentPage > 0;
    final canGoNext =
        _pageSize != -1 &&
        (_currentPage + 1) * safePageSize < filteredTasks.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showStatusFilters) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusFilterChip('All', 'all'),
              _statusFilterChip('To Do', TaskStatus.todo.code),
              _statusFilterChip('In Progress', TaskStatus.inProgress.code),
              _statusFilterChip('In Review', TaskStatus.inReview.code),
              _statusFilterChip('On Hold', TaskStatus.onHold.code),
              _statusFilterChip('Complete', TaskStatus.complete.code),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${filteredTasks.length} tasks',
              style: AppTypography.helper.copyWith(
                color: surface.textSecondary,
              ),
            ),
            Row(
              children: [
                Text(
                  'Rows:',
                  style: AppTypography.helper.copyWith(
                    color: surface.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    initialValue: _pageSize,
                    dropdownColor: surface.panel,
                    style: AppTypography.body.copyWith(
                      color: surface.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem<int>(value: 10, child: Text('10')),
                      DropdownMenuItem<int>(value: 20, child: Text('20')),
                      DropdownMenuItem<int>(value: 50, child: Text('50')),
                      DropdownMenuItem<int>(value: 100, child: Text('100')),
                      DropdownMenuItem<int>(value: -1, child: Text('All')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _pageSize = value;
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredTasks.isEmpty)
          AppEmptyState(
            icon: Icons.search_off,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final categories = categoriesAsync.asData?.value ?? const [];
              final categoryMap = {
                for (final category in categories) category.id: category.name,
                AppDatabase.uncategorizedCategoryId: 'Uncategorized',
              };
              final compact = constraints.maxWidth < 900;

              return Column(
                children: [
                  ...visibleTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.spacing12,
                      ),
                      child: _TaskListItem(
                        task: task,
                        categoryName:
                            categoryMap[task.categoryId] ?? 'Uncategorized',
                        isRunning: widget.timerRunningTaskId == task.id,
                        currentRunningElapsedSeconds:
                            widget.currentRunningElapsedSeconds,
                        onStartStopPressed: widget.onStartStopPressed,
                        onViewPressed: widget.onViewPressed,
                        onEditPressed: widget.onEditPressed,
                        onDeletePressed: widget.onDeletePressed,
                        onArchivePressed: widget.onArchivePressed,
                        onRestorePressed: widget.onRestorePressed,
                        readOnly: widget.readOnly,
                        compact: compact,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        if (_pageSize != -1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton.secondary(
                label: AppStrings.buttons.previous,
                onPressed: canGoPrevious
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: AppTypography.helper.copyWith(
                  color: surface.textSecondary,
                ),
              ),
              AppButton.secondary(
                label: AppStrings.buttons.next,
                onPressed: canGoNext
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
      ],
    );
  }

  Widget _statusFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) {
        setState(() {
          _statusFilter = value;
          _currentPage = 0;
        });
      },
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final TaskEntity task;
  final String categoryName;
  final bool isRunning;
  final int currentRunningElapsedSeconds;
  final Function(TaskEntity task) onStartStopPressed;
  final Function(TaskEntity task) onViewPressed;
  final Function(TaskEntity task) onEditPressed;
  final Function(TaskEntity task) onDeletePressed;
  final Function(TaskEntity task)? onArchivePressed;
  final Function(TaskEntity task)? onRestorePressed;
  final bool readOnly;
  final bool compact;

  const _TaskListItem({
    required this.task,
    required this.categoryName,
    required this.isRunning,
    required this.currentRunningElapsedSeconds,
    required this.onStartStopPressed,
    required this.onViewPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.readOnly,
    required this.compact,
    this.onArchivePressed,
    this.onRestorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);
    final status = TaskStatus.fromValue(task.status);
    final durationSeconds = isRunning
        ? (currentRunningElapsedSeconds > task.totalSeconds
              ? currentRunningElapsedSeconds
              : task.totalSeconds)
        : task.totalSeconds;
    final actualHours = durationSeconds / 3600.0;
    final estimatedHours = task.estimatedHours;
    final estimateVariance = estimatedHours == null
        ? null
        : actualHours - estimatedHours;
    final estimateVarianceLabel = estimateVariance == null
        ? null
        : estimateVariance > 0
        ? '+${estimateVariance.toStringAsFixed(2)}h over'
        : estimateVariance < 0
        ? '${estimateVariance.toStringAsFixed(2)}h under'
        : 'On target';
    final estimateVarianceColor = estimateVariance == null
        ? null
        : estimateVariance > 0
        ? AppColors.error
        : estimateVariance < 0
        ? AppColors.success
        : AppColors.info;
    final description = task.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surface.panel,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(color: surface.border),
      ),
      padding: const EdgeInsets.all(AppConstants.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 54,
                child: Center(
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    tooltip: isRunning
                        ? AppStrings.buttons.stop
                        : AppStrings.buttons.start,
                    onPressed: () => onStartStopPressed(task),
                    icon: Icon(
                      isRunning ? Icons.stop : Icons.play_arrow,
                      color: isRunning ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
            ),
          if (!readOnly) const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: task.taskName,
                        waitDuration: const Duration(milliseconds: 350),
                        child: Text(
                          task.taskName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.actionLabel.copyWith(
                            color: surface.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More actions',
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            onViewPressed(task);
                            break;
                          case 'edit':
                            onEditPressed(task);
                            break;
                          case 'delete':
                            onDeletePressed(task);
                            break;
                          case 'archive':
                            onArchivePressed?.call(task);
                            break;
                          case 'restore':
                            onRestorePressed?.call(task);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View'),
                          ),
                        ];

                        if (readOnly) {
                          if (onRestorePressed != null) {
                            items.add(
                              const PopupMenuItem(
                                value: 'restore',
                                child: Text('Restore'),
                              ),
                            );
                          }
                        } else {
                          items.addAll([
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                            if (status == TaskStatus.complete &&
                                onArchivePressed != null)
                              const PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive'),
                              ),
                          ]);
                        }

                        return items;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing4),
                Text(
                  hasDescription ? description : 'No details provided',
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: surface.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing8),
                Wrap(
                  spacing: AppConstants.spacing8,
                  runSpacing: AppConstants.spacing8,
                  children: [
                    _Tag(text: categoryName, color: AppColors.brandPrimary),
                    _Tag(
                      text: task.isBillable ? 'Billable' : 'Non-billable',
                      color: AppColors.info,
                    ),
                    _Tag(
                      text: DateTimeFormatter.formatSeconds(durationSeconds),
                      color: AppColors.warning,
                    ),
                    _Tag(
                      text: estimatedHours == null
                          ? 'Estimate: Not set'
                          : 'Estimate: ${estimatedHours.toStringAsFixed(2)}h',
                      color: estimatedHours == null
                          ? surface.textSecondary
                          : AppColors.brandPrimary,
                    ),
                    if (estimateVarianceLabel != null &&
                        estimateVarianceColor != null)
                      _Tag(
                        text: estimateVarianceLabel,
                        color: estimateVarianceColor,
                      ),
                    _Tag(text: status.label, color: status.getColor()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: AppTypography.helper.copyWith(color: color)),
    );
  }
}
