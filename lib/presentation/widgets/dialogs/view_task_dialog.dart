import 'package:flutter/material.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/task_entity.dart';

/// View Task Dialog
/// Opens as a modal dialog to view task details in read-only format
class ViewTaskDialog extends StatelessWidget {
  final TaskEntity task;

  const ViewTaskDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final status = TaskStatus.values.firstWhere(
      (s) => s.label == task.status,
      orElse: () => TaskStatus.todo,
    );

    return AlertDialog(
      title: Text('Task Details', style: AppTextStyles.heading2),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Task Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(task.taskName, style: AppTextStyles.heading2),
              ],
            ),
            const SizedBox(height: 20),

            // Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status.getColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: status.getColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Total Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Time Tracked',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSeconds(task.totalSeconds),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Created Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created On',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(task.createdAt),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Running Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  task.isRunning ? 'Currently Running' : 'Not Running',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: task.isRunning ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            if (task.description != null && task.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(task.description!, style: AppTextStyles.bodySmall),
                ],
              ),
          ],
        ),
      ),
      actions: [
        AppButton.secondary(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
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
