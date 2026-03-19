import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';

/// Running Timer Card Widget
/// Displays the currently running task timer with controls
class RunningTimerCard extends StatelessWidget {
  final String projectName;
  final String taskName;
  final String elapsedTime; // Format: HH:MM:SS
  final VoidCallback? onPausePressed;
  final VoidCallback? onStopPressed;

  const RunningTimerCard({
    Key? key,
    required this.projectName,
    required this.taskName,
    required this.elapsedTime,
    this.onPausePressed,
    this.onStopPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing24),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Label
          Text(
            'Currently Working On',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(height: AppConstants.spacing12),

          // Project and Task Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                projectName,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppConstants.spacing4),
              Text(
                taskName,
                style: AppTextStyles.heading2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing24),

          // Timer Display
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withOpacity(0.5)
                  : AppColors.lightSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              border: Border.all(
                color: AppColors.brandPrimary.withOpacity(0.2),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacing24,
              vertical: AppConstants.spacing20,
            ),
            child: Text(
              elapsedTime,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
                letterSpacing: 2,
              ),
            ),
          ),

          SizedBox(height: AppConstants.spacing24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPausePressed,
                  borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing24,
                      vertical: AppConstants.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(
                        AppConstants.roundRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        SizedBox(width: AppConstants.spacing8),
                        Text(
                          'Pause',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: AppConstants.spacing16),

              // Stop Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onStopPressed,
                  borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing24,
                      vertical: AppConstants.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(
                        AppConstants.roundRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop, size: 20, color: Colors.white),
                        SizedBox(width: AppConstants.spacing8),
                        Text(
                          'Stop',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
