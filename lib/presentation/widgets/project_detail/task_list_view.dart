import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/task_entity.dart';
import 'empty_tasks_state.dart';
import 'task_list_item.dart';

/// Displays paginated list of project tasks
class TaskListView extends StatefulWidget {
  final List<TaskEntity> tasks;
  final String? timerRunningTaskId;
  final bool isTimerRunning;
  final int currentRunningElapsedSeconds;
  final Function(TaskEntity task) onViewPressed;
  final Function(TaskEntity task) onStartStopPressed;
  final Function(TaskEntity task) onEditPressed;
  final Function(TaskEntity task) onDeletePressed;

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
    this.tasksPerPage = 20,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const EmptyTasksState();
    }

    // Calculate pagination
    final totalPages = (widget.tasks.length / widget.tasksPerPage).ceil();
    final start = _currentPage * widget.tasksPerPage;
    final end = (start + widget.tasksPerPage).clamp(0, widget.tasks.length);
    final paginatedTasks = widget.tasks.sublist(start, end);

    return Column(
      children: [
        // Task list
        ...paginatedTasks.map((task) {
          return TaskListItem(
            task: task,
            isTimerRunning: widget.isTimerRunning,
            isThisTaskRunning: widget.timerRunningTaskId == task.id,
            currentRunningElapsedSeconds: widget.currentRunningElapsedSeconds,
            onViewPressed: () => widget.onViewPressed(task),
            onStartStopPressed: () => widget.onStartStopPressed(task),
            onEditPressed: () => widget.onEditPressed(task),
            onDeletePressed: () => widget.onDeletePressed(task),
          );
        }),
        const SizedBox(height: 16),
        // Pagination controls
        if (widget.tasks.length > widget.tasksPerPage)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton.secondary(
                label: AppStrings.buttons.previous,
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: AppTextStyles.bodySmall,
              ),
              AppButton.secondary(
                label: AppStrings.buttons.next,
                onPressed:
                    (_currentPage + 1) * widget.tasksPerPage <
                        widget.tasks.length
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}
