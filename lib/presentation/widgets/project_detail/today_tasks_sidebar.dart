import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/entities/task_entity.dart';

/// Sidebar displaying tasks created today
class TodayTasksSidebar extends StatelessWidget {
  final List<TaskEntity> todaysTasks;

  const TodayTasksSidebar({super.key, required this.todaysTasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.screenTitles.todaysTasks,
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 16),
        if (todaysTasks.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                AppStrings.labels.noTasksCreatedToday,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFFA0AEC0),
                ),
              ),
            ),
          )
        else
          Column(
            children: todaysTasks
                .map((task) => _buildTodayTaskItem(task))
                .toList(),
          ),
      ],
    );
  }

  /// Build individual today's task item
  Widget _buildTodayTaskItem(TaskEntity task) {
    final taskStatus = TaskStatus.values.firstWhere(
      (s) => s.label == task.status,
      orElse: () => TaskStatus.todo,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task name
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: AppTextStyles.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Duration and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateTimeFormatter.formatSeconds(task.totalSeconds),
                  style: AppTextStyles.bodySmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: taskStatus.getColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    task.status,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: taskStatus.getColor(),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
