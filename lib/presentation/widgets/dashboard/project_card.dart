import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/task_status.dart';
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
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final Color? color;

  const ProjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.hours,
    required this.avatarEmoji,
    this.recentTasks,
    this.onViewPressed,
    this.onEditPressed,
    this.onDeletePressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);
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
                  color: projectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                ),
                child: Center(
                  child: Text(avatarEmoji, style: TextStyle(fontSize: 28)),
                ),
              ),
              // Action Buttons (Edit, Delete, View)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  if (onEditPressed != null)
                    Tooltip(
                      message: 'Edit Project',
                      child: IconButton(
                        icon: Icon(Icons.edit, size: 18, color: projectColor),
                        onPressed: onEditPressed,
                        padding: EdgeInsets.all(AppConstants.spacing4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  // Delete Button
                  if (onDeletePressed != null)
                    Tooltip(
                      message: 'Delete Project',
                      child: IconButton(
                        icon: Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: onDeletePressed,
                        padding: EdgeInsets.all(AppConstants.spacing4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  SizedBox(width: AppConstants.spacing4),
                  // View Button
                  InkWell(
                    onTap: onViewPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing12,
                        vertical: AppConstants.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: projectColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.roundRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: projectColor,
                          ),
                          SizedBox(width: AppConstants.spacing4),
                          Text(
                            'View',
                            style: AppTypography.actionLabel.copyWith(
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
            ],
          ),

          SizedBox(height: AppConstants.spacing12),

          // Project Name and Description
          Text(
            title,
            style: AppTypography.sectionTitle.copyWith(
              color: surface.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppConstants.spacing4),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: surface.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Total Hours
          Text(
            'Total Hours',
            style: AppTypography.label.copyWith(color: surface.textMuted),
          ),
          Text(
            hours,
            style: AppTypography.metricValue.copyWith(
              color: projectColor,
              fontSize: AppConstants.fontSizeLarge,
            ),
          ),

          SizedBox(height: AppConstants.spacing12),

          // Divider
          Divider(height: 1, color: surface.border),

          SizedBox(height: AppConstants.spacing12),

          // Recent Tasks
          if (recentTasks != null && recentTasks!.isNotEmpty) ...[
            Text(
              'Recent Tasks',
              style: AppTypography.actionLabel.copyWith(
                fontWeight: FontWeight.w600,
                color: surface.textPrimary,
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
                        style: AppTypography.bodySmall.copyWith(
                          color: surface.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing8),
                    _TaskStatusBadge(status: task.status),
                  ],
                ),
              );
            }),
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
    return TaskStatus.fromValue(status).getColor();
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
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        TaskStatus.formatLabel(status),
        style: AppTypography.label.copyWith(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
