import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/task_status.dart';
import '../../../core/constants/colors.dart';
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
    final surface = AppSurfaceTokens(isDark: isDark);
    final taskTitle = (activeTask?.taskName ?? 'Task').trim();
    final taskDescription = (activeTask?.description ?? '').trim();
    final showDescription = taskDescription.isNotEmpty;
    final status = TaskStatus.fromValue(
      activeTask?.status ?? TaskStatus.inProgress.code,
    );
    final statusColor = status.getColor();

    return AppCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: surface.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.labels.currentlyTracking,
                  style: AppTypography.actionLabel.copyWith(
                    color: surface.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  TaskStatus.formatLabel(status.code),
                  style: AppTypography.label.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Active task details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: taskTitle,
                waitDuration: const Duration(milliseconds: 350),
                child: Text(
                  taskTitle,
                  style: AppTypography.sectionTitle.copyWith(
                    color: surface.textPrimary,
                  ),
                  maxLines: AppConstants.maxTitleDisplayLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Task Details',
                style: AppTypography.label.copyWith(
                  color: surface.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: surface.panelLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: surface.border),
                ),
                child: showDescription
                    ? SingleChildScrollView(
                        child: SelectableText(
                          taskDescription,
                          style: AppTypography.body.copyWith(
                            color: surface.textPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'No task description provided yet.',
                        style: AppTypography.body.copyWith(
                          color: surface.textSecondary,
                        ),
                      ),
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
