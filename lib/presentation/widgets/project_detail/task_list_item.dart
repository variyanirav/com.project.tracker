import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/entities/task_entity.dart';

/// Individual task card item with action buttons
class TaskListItem extends StatelessWidget {
  final TaskEntity task;
  final bool isTimerRunning;
  final bool isThisTaskRunning;
  final int? currentRunningElapsedSeconds;
  final VoidCallback onViewPressed;
  final VoidCallback onStartStopPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const TaskListItem({
    super.key,
    required this.task,
    required this.isTimerRunning,
    required this.isThisTaskRunning,
    this.currentRunningElapsedSeconds,
    required this.onViewPressed,
    required this.onStartStopPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final displaySeconds =
        isThisTaskRunning && currentRunningElapsedSeconds != null
        ? (currentRunningElapsedSeconds! > task.totalSeconds
              ? currentRunningElapsedSeconds!
              : task.totalSeconds)
        : task.totalSeconds;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: AppTextStyles.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            // Metadata: Duration & Date
            Text(
              '${DateTimeFormatter.formatSeconds(displaySeconds)} · ${DateTimeFormatter.formatDate(task.createdAt)}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            // Action Buttons Row
            Row(
              children: [
                // View Button
                _buildActionButton(
                  icon: Icons.info_outline,
                  color: Colors.purple,
                  tooltip: AppStrings.hints.viewTaskDetails,
                  onPressed: onViewPressed,
                ),
                const SizedBox(width: 12),
                // Start/Stop Timer Button
                Expanded(child: _buildTimerButton()),
                const SizedBox(width: 12),
                // Edit Button
                _buildActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  tooltip: AppStrings.hints.editTask,
                  onPressed: onEditPressed,
                ),
                const SizedBox(width: 12),
                // Delete Button
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  tooltip: AppStrings.hints.deleteTask,
                  onPressed: onDeletePressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge() {
    final taskStatus = TaskStatus.values.firstWhere(
      (s) => s.label == task.status,
      orElse: () => TaskStatus.todo,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: taskStatus.getColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        task.status,
        style: AppTextStyles.labelSmall.copyWith(
          color: taskStatus.getColor(),
          fontSize: 11,
        ),
      ),
    );
  }

  /// Build generic action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        ),
      ),
    );
  }

  /// Build timer start/stop button
  Widget _buildTimerButton() {
    final buttonColor = isThisTaskRunning ? Colors.orange : Colors.green;
    final buttonIcon = isThisTaskRunning ? Icons.stop : Icons.play_arrow;
    final buttonLabel = isThisTaskRunning
        ? AppStrings.buttons.stop
        : AppStrings.buttons.start;

    return Container(
      decoration: BoxDecoration(
        color: buttonColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: buttonColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStartStopPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 18, color: buttonColor),
                const SizedBox(width: 6),
                Text(
                  buttonLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: buttonColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
