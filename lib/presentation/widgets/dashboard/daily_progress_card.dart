import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/timer_provider.dart';

/// Daily progress card showing progress towards daily goal
class DailyProgressCard extends ConsumerWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch providers for real data
    final todayHoursAsync = ref.watch(todayTotalHoursProvider);
    final dailyGoalAsync = ref.watch(dailyGoalProvider);
    final dailyProgressAsync = ref.watch(dailyProgressProvider);

    // Use .when() to handle loading/error states
    return todayHoursAsync.when(
      data: (todayHours) => dailyGoalAsync.when(
        data: (dailyGoalHours) => dailyProgressAsync.when(
          data: (progress) {
            // Convert hours to hours and minutes
            final todayHoursPart = todayHours.toInt();
            final todayMinutesPart = ((todayHours - todayHoursPart) * 60)
                .toInt();

            final goalHoursPart = dailyGoalHours.toInt();
            final goalMinutesPart = ((dailyGoalHours - goalHoursPart) * 60)
                .toInt();

            // Calculate a friendly progress message
            final progressMessage = progress >= 1.0
                ? 'Great job! You\'ve completed your daily goal!'
                : progress >= 0.75
                ? 'Almost there! You\'re doing great.'
                : progress >= 0.5
                ? 'Halfway there! Keep going.'
                : 'Get started! Log some time to track progress.';

            return AppCard(
              padding: EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Progress',
                          style: AppTextStyles.titleMedium,
                        ),
                        SizedBox(height: AppConstants.spacing8),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}% of your daily goal. $progressMessage',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacing24),
                        // Stats row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Logged
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Logged',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                                SizedBox(height: AppConstants.spacing4),
                                Text(
                                  '${todayHoursPart}h ${todayMinutesPart}m',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppColors.brandPrimary,
                                    fontSize: 28.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: AppConstants.spacing32),
                            // Daily Goal
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Goal',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                                SizedBox(height: AppConstants.spacing4),
                                Text(
                                  '${goalHoursPart}h ${goalMinutesPart.toString().padLeft(2, '0')}m',
                                  style: AppTextStyles.heading2.copyWith(
                                    fontSize: 28.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side - Radial progress
                  Padding(
                    padding: EdgeInsets.only(left: AppConstants.spacing32),
                    child: _buildRadialProgress(progress),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildLoadingCard(isDark),
          error: (error, stack) => _buildErrorCard(isDark, error.toString()),
        ),
        loading: () => _buildLoadingCard(isDark),
        error: (error, stack) => _buildErrorCard(isDark, error.toString()),
      ),
      loading: () => _buildLoadingCard(isDark),
      error: (error, stack) => _buildErrorCard(isDark, error.toString()),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Progress', style: AppTextStyles.titleMedium),
                SizedBox(height: AppConstants.spacing8),
                Text(
                  'Loading progress...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: AppConstants.spacing32),
            child: SizedBox(
              width: 160,
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark, String error) {
    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Progress', style: AppTextStyles.titleMedium),
                SizedBox(height: AppConstants.spacing8),
                Text(
                  'Error loading progress. Please try again.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialProgress(double progress) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(160, 160),
            painter: _RadialProgressPainter(
              progress: 1.0,
              color: AppColors.darkBorder.withValues(alpha: 0.2),
              width: 12,
            ),
          ),
          // Progress circle
          CustomPaint(
            size: Size(160, 160),
            painter: _RadialProgressPainter(
              progress: progress,
              color: AppColors.brandPrimary,
              width: 12,
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.heading1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;

  _RadialProgressPainter({
    required this.progress,
    required this.color,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - width) / 2;

    // Draw arc
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      progress * 2 * 3.14159,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
