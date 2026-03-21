import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/timer_provider.dart';
import 'timer_control_buttons.dart';

/// Displays currently active timer information and controls
class ActiveTimerCard extends ConsumerWidget {
  final TaskEntity? activeTask;
  final TimerState timerState;
  final AsyncValue<TimerState> timerTickAsync;
  final bool isDark;
  final VoidCallback onPauseStartPressed;
  final VoidCallback onStopPressed;

  const ActiveTimerCard({
    super.key,
    required this.activeTask,
    required this.timerState,
    required this.timerTickAsync,
    required this.isDark,
    required this.onPauseStartPressed,
    required this.onStopPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.labels.currentlyTracking,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 16),
          // Active task details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeTask?.taskName ?? 'Task',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    activeTask?.description ?? AppStrings.labels.inProgress,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TaskStatus.inProgress.getColor().withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppStrings.labels.inProgress,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: TaskStatus.inProgress.getColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Timer display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: timerTickAsync.when(
                data: (tickTimer) => Text(
                  DateTimeFormatter.formatElapsedTime(tickTimer.elapsedSeconds),
                  style: AppTextStyles.timerDisplay.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                loading: () => Text(
                  DateTimeFormatter.formatElapsedTime(
                    timerState.elapsedSeconds,
                  ),
                  style: AppTextStyles.timerDisplay.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                error: (err, stack) => Text(
                  DateTimeFormatter.formatElapsedTime(
                    timerState.elapsedSeconds,
                  ),
                  style: AppTextStyles.timerDisplay.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Control buttons
          TimerControlButtons(
            isPaused: timerState.isPaused,
            onPauseStartPressed: onPauseStartPressed,
            onStopPressed: onStopPressed,
          ),
        ],
      ),
    );
  }
}
