import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';

/// Task model for recent tasks display
class RecentTask {
  final String name;
  final String status; // 'To Do', 'In Progress', 'In Review', 'Complete'

  const RecentTask({required this.name, required this.status});
}

/// Project card widget for displaying project information
class ProjectCard extends StatelessWidget {
  final String title;
  final String description;
  final String hours;
  final String avatarEmoji;
  final List<RecentTask>? recentTasks;
  final VoidCallback? onViewPressed;
  final Color? color;

  const ProjectCard({
    Key? key,
    required this.title,
    required this.description,
    required this.hours,
    required this.avatarEmoji,
    this.recentTasks,
    this.onViewPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectColor = color ?? AppColors.brandPrimary;

    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Avatar and View Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: projectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                ),
                child: Center(
                  child: Text(avatarEmoji, style: TextStyle(fontSize: 28)),
                ),
              ),
              // View Button
              InkWell(
                onTap: onViewPressed,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing12,
                    vertical: AppConstants.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: projectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.roundRadius,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward, size: 16, color: projectColor),
                      SizedBox(width: AppConstants.spacing4),
                      Text(
                        'View',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: projectColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing12),

          // Project Name and Description
          Text(
            title,
            style: AppTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppConstants.spacing4),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Total Hours
          Text(
            'Total Hours',
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          Text(
            hours,
            style: AppTextStyles.titleMedium.copyWith(color: projectColor),
          ),

          SizedBox(height: AppConstants.spacing12),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Recent Tasks
          if (recentTasks != null && recentTasks!.isNotEmpty) ...[
            Text(
              'Recent Tasks',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacing8),
            ...recentTasks!.take(2).map((task) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacing8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing8),
                    _TaskStatusBadge(status: task.status),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

/// Task Status Badge Widget
class _TaskStatusBadge extends StatelessWidget {
  final String status;

  const _TaskStatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.grey;
      case 'in progress':
        return Colors.blue;
      case 'in review':
        return Colors.amber;
      case 'complete':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: AppConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall.copyWith(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
