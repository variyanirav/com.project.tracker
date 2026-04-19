import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/live_hours_overlay.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/timer_provider.dart';

/// Daily progress card showing progress towards daily goal.
class DailyProgressCard extends ConsumerWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);

    final todayHoursAsync = ref.watch(todayTotalHoursProvider);
    final dailyGoalAsync = ref.watch(dailyGoalProvider);
    final timerState = ref.watch(timerProvider);

    return todayHoursAsync.when(
      data: (todayHours) => dailyGoalAsync.when(
        data: (dailyGoalHours) {
          final liveTodayHours = LiveHoursOverlay.withLiveOverlay(
            persistedHours: todayHours,
            isTimerRunning: timerState.isRunning,
            elapsedSeconds: timerState.elapsedSeconds,
            timerStartTime: timerState.startTime,
            timerProjectId: timerState.projectId,
            scope: LiveHoursScope.today,
          );
          final progress = dailyGoalHours == 0
              ? 0.0
              : (liveTodayHours / dailyGoalHours).clamp(0.0, 1.0);

          final todayHoursPart = liveTodayHours.toInt();
          final todayMinutesPart = ((liveTodayHours - todayHoursPart) * 60)
              .toInt();

          final goalHoursPart = dailyGoalHours.toInt();
          final goalMinutesPart = ((dailyGoalHours - goalHoursPart) * 60)
              .toInt();

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Progress',
                        style: AppTypography.sectionTitle.copyWith(
                          color: surface.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% of your daily goal. $progressMessage',
                        style: AppTypography.body.copyWith(
                          color: surface.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Logged',
                                style: AppTypography.label.copyWith(
                                  color: surface.textMuted,
                                ),
                              ),
                              SizedBox(height: AppConstants.spacing4),
                              Text(
                                '${todayHoursPart}h ${todayMinutesPart}m',
                                style: AppTypography.metricValue.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontSize: 28.0,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: AppConstants.spacing32),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Goal',
                                style: AppTypography.label.copyWith(
                                  color: surface.textMuted,
                                ),
                              ),
                              SizedBox(height: AppConstants.spacing4),
                              Text(
                                '${goalHoursPart}h ${goalMinutesPart.toString().padLeft(2, '0')}m',
                                style: AppTypography.metricValue.copyWith(
                                  fontSize: 28.0,
                                  color: surface.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: AppConstants.spacing32),
                  child: _buildRadialProgress(progress, surface),
                ),
              ],
            ),
          );
        },
        loading: () => _buildLoadingCard(surface),
        error: (_, __) => _buildErrorCard(surface),
      ),
      loading: () => _buildLoadingCard(surface),
      error: (_, __) => _buildErrorCard(surface),
    );
  }

  Widget _buildLoadingCard(AppSurfaceTokens surface) {
    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: AppTypography.sectionTitle.copyWith(
                    color: surface.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.spacing8),
                Text(
                  'Loading progress...',
                  style: AppTypography.body.copyWith(
                    color: surface.textSecondary,
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

  Widget _buildErrorCard(AppSurfaceTokens surface) {
    return AppCard(
      padding: EdgeInsets.all(AppConstants.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: AppTypography.sectionTitle.copyWith(
                    color: surface.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.spacing8),
                Text(
                  'Error loading progress. Please try again.',
                  style: AppTypography.body.copyWith(
                    color: surface.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialProgress(double progress, AppSurfaceTokens surface) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(160, 160),
            painter: _RadialProgressPainter(
              progress: 1.0,
              color: surface.border.withValues(alpha: 0.2),
              width: 12,
            ),
          ),
          CustomPaint(
            size: Size(160, 160),
            painter: _RadialProgressPainter(
              progress: progress,
              color: AppColors.brandPrimary,
              width: 12,
            ),
          ),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: AppTypography.metricValue.copyWith(
              color: surface.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  _RadialProgressPainter({
    required this.progress,
    required this.color,
    required this.width,
  });

  final double progress;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - width) / 2;

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
