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
  final bool isPaused;
  final VoidCallback? onTogglePausePressed;
  final VoidCallback? onStopPressed;

  const RunningTimerCard({
    super.key,
    required this.projectName,
    required this.taskName,
    required this.elapsedTime,
    this.isPaused = false,
    this.onTogglePausePressed,
    this.onStopPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing24),
      backgroundColor: surface.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Label
          Text(
            'Currently Working On',
            style: AppTypography.label.copyWith(
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
                style: AppTypography.actionLabel.copyWith(
                  color: surface.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppConstants.spacing4),
              Text(
                taskName,
                style: AppTypography.sectionTitle.copyWith(
                  color: surface.textPrimary,
                ),
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
              color: surface.panelHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              border: Border.all(
                color: AppColors.brandPrimary.withValues(alpha: 0.2),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacing24,
              vertical: AppConstants.spacing20,
            ),
            child: Text(
              elapsedTime,
              style: AppTypography.metricValue.copyWith(
                fontFamily: 'Courier New',
                fontSize: 48,
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
              // Pause/Start Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTogglePausePressed,
                  borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing24,
                      vertical: AppConstants.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: surface.panelHigh,
                      borderRadius: BorderRadius.circular(
                        AppConstants.roundRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaused ? Icons.play_arrow : Icons.pause,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        SizedBox(width: AppConstants.spacing8),
                        Text(
                          isPaused ? 'Start' : 'Pause',
                          style: AppTypography.actionLabel.copyWith(
                            color: surface.textPrimary,
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
                          style: AppTypography.actionLabel.copyWith(
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
