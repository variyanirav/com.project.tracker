import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';

/// Daily progress card showing progress towards daily goal
class DailyProgressCard extends StatelessWidget {
  final double progress;
  final int hoursLogged;
  final int minutesLogged;
  final int dailyGoalHours;
  final int dailyGoalMinutes;

  const DailyProgressCard({
    Key? key,
    this.progress = 0.68,
    this.hoursLogged = 5,
    this.minutesLogged = 24,
    this.dailyGoalHours = 8,
    this.dailyGoalMinutes = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Text('Daily Progress', style: AppTextStyles.titleMedium),
                SizedBox(height: AppConstants.spacing8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% of your daily goal. Keep going, you\'re ahead of schedule!',
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
                          '${hoursLogged}h ${minutesLogged}m',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.brandPrimary,
                            fontSize: 28.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: AppConstants.spacing40),
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
                          '${dailyGoalHours}h ${dailyGoalMinutes.toString().padLeft(2, '0')}m',
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
              color: AppColors.darkBorder.withOpacity(0.2),
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
