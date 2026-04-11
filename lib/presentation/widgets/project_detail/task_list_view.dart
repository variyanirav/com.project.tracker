import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_tracker/data/database/app_database.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../presentation/providers/category_provider.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/task_entity.dart';
import 'empty_tasks_state.dart';

/// Displays project tasks in a filterable, paginated table layout.
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
  final ScrollController _tableHorizontalScrollController = ScrollController();

  @override
  void dispose() {
    _tableHorizontalScrollController.dispose();
    super.dispose();
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
    final paginatedTasks = _paginatedTasks;

    final pageSize = _pageSize == -1 ? filteredTasks.length : _pageSize;
    final safePageSize = pageSize == 0 ? 1 : pageSize;
    final totalPages = filteredTasks.isEmpty
        ? 1
        : (filteredTasks.length / safePageSize).ceil();

    final canGoPrevious = _pageSize != -1 && _currentPage > 0;
    final canGoNext =
        _pageSize != -1 &&
        (_currentPage + 1) * safePageSize < filteredTasks.length;
    final showFilters = widget.showStatusFilters;
    final isReadOnly = widget.readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFilters) ...[
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
              style: AppTextStyles.bodySmall,
            ),
            Row(
              children: [
                Text('Rows:', style: AppTextStyles.bodySmall),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    initialValue: _pageSize,
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
              final compact = constraints.maxWidth < 1300;
              final columns = <DataColumn>[
                const DataColumn(label: Text('Task ID')),
                const DataColumn(label: Text('Name')),
                if (!compact) const DataColumn(label: Text('Description')),
                if (!isReadOnly) const DataColumn(label: Text('Running')),
                const DataColumn(label: Text('Status')),
                const DataColumn(label: Text('Category')),
                const DataColumn(label: Text('Duration')),
                if (!compact) const DataColumn(label: Text('Created')),
                if (!isReadOnly) const DataColumn(label: Text('Timer')),
                const DataColumn(label: Text('Actions')),
              ];

              return Scrollbar(
                controller: _tableHorizontalScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _tableHorizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 46,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 72,
                      columns: columns,
                      rows: paginatedTasks.map((task) {
                        final isRunning = widget.timerRunningTaskId == task.id;
                        final runningLabel = isRunning ? 'Running' : 'Idle';
                        final status = TaskStatus.fromValue(task.status);
                        final durationSeconds = isRunning
                            ? (widget.currentRunningElapsedSeconds >
                                      task.totalSeconds
                                  ? widget.currentRunningElapsedSeconds
                                  : task.totalSeconds)
                            : task.totalSeconds;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                task.id.length > 8
                                    ? task.id.substring(0, 8)
                                    : task.id,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: compact ? 180 : 220,
                                child: Tooltip(
                                  message: task.taskName,
                                  child: Text(
                                    task.taskName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            if (!compact)
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Tooltip(
                                    message: task.description ?? '-',
                                    child: Text(
                                      (task.description?.trim().isNotEmpty ??
                                              false)
                                          ? task.description!
                                          : '-',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            if (!isReadOnly)
                              DataCell(_runningBadge(runningLabel)),
                            DataCell(_statusBadge(status)),
                            DataCell(
                              Text(
                                categoryMap[task.categoryId] ?? 'Uncategorized',
                              ),
                            ),
                            DataCell(
                              Text(
                                DateTimeFormatter.formatSeconds(
                                  durationSeconds,
                                ),
                              ),
                            ),
                            if (!compact)
                              DataCell(
                                Text(
                                  DateTimeFormatter.formatDate(task.createdAt),
                                ),
                              ),
                            if (!isReadOnly)
                              DataCell(
                                IconButton(
                                  tooltip: isRunning
                                      ? AppStrings.buttons.stop
                                      : AppStrings.buttons.start,
                                  onPressed: () =>
                                      widget.onStartStopPressed(task),
                                  icon: Icon(
                                    isRunning
                                        ? Icons.stop_circle
                                        : Icons.play_circle,
                                    color: isRunning
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: isReadOnly
                                    ? [
                                        IconButton(
                                          tooltip:
                                              AppStrings.hints.viewTaskDetails,
                                          onPressed: () =>
                                              widget.onViewPressed(task),
                                          icon: const Icon(Icons.info_outline),
                                        ),
                                        if (widget.onRestorePressed != null)
                                          IconButton(
                                            tooltip: 'Restore Task',
                                            onPressed: () =>
                                                widget.onRestorePressed!(task),
                                            icon: const Icon(
                                              Icons.unarchive_outlined,
                                            ),
                                          ),
                                      ]
                                    : [
                                        IconButton(
                                          tooltip:
                                              AppStrings.hints.viewTaskDetails,
                                          onPressed: () =>
                                              widget.onViewPressed(task),
                                          icon: const Icon(Icons.info_outline),
                                        ),
                                        IconButton(
                                          tooltip: AppStrings.hints.editTask,
                                          onPressed: () =>
                                              widget.onEditPressed(task),
                                          icon: const Icon(Icons.edit),
                                        ),
                                        IconButton(
                                          tooltip: AppStrings.hints.deleteTask,
                                          onPressed: () =>
                                              widget.onDeletePressed(task),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                        if (status == TaskStatus.complete &&
                                            widget.onArchivePressed != null)
                                          IconButton(
                                            tooltip: 'Archive Task',
                                            onPressed: () =>
                                                widget.onArchivePressed!(task),
                                            icon: const Icon(
                                              Icons.archive_outlined,
                                            ),
                                          ),
                                      ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
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
                style: AppTextStyles.bodySmall,
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

  Widget _runningBadge(String text) {
    final isRunning = text == 'Running';
    final color = isRunning ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  Widget _statusBadge(TaskStatus status) {
    final color = status.getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
