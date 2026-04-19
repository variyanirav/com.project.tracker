import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../domain/entities/focus_cycle_template_entity.dart';
import '../../domain/entities/focus_goal_entity.dart';
import '../../domain/entities/focus_run_state_entity.dart';
import '../../services/focus_notification_service.dart';
import '../providers/focus_timer_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/focus_timer_settings_dialog.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> {
  FocusGoalEntity _goal = const FocusGoalEntity.defaultHour();
  FocusCycleTemplateEntity _template =
      const FocusCycleTemplateEntity.standard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppSurfaceTokens(isDark: isDark);
    final state = ref.watch(focusTimerProvider);

    ref.listen<FocusRunStateEntity>(focusTimerProvider, (previous, next) async {
      if (previous == null || previous.phase == next.phase) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      final service = ref.read(focusNotificationServiceProvider);
      final success = await service.notifyPhaseChange(next.phase);
      if (!mounted || success) {
        return;
      }

      if (next.phase == FocusRunPhase.shortBreak ||
          next.phase == FocusRunPhase.longBreak) {
        messenger.showSnackBar(const SnackBar(content: Text('Break started')));
      } else if (next.phase == FocusRunPhase.focus) {
        messenger.showSnackBar(const SnackBar(content: Text('Focus resumed')));
      } else if (next.phase == FocusRunPhase.completed) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Focus goal completed')),
        );
      }
    });

    final notifier = ref.read(focusTimerProvider.notifier);
    final progress = notifier.progress();

    return CustomScaffold(
      activeRoute: AppRouter.focusTimer,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Focus Timer Settings',
            child: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _openSettings,
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Tooltip(
            message: ref.watch(themeProvider) ? 'Light Mode' : 'Dark Mode',
            child: IconButton(
              icon: Icon(
                ref.watch(themeProvider) ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => ref.read(themeProvider.notifier).toggle(),
            ),
          ),
        ],
      ),
      child: ColoredBox(
        color: surface.page,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Timer',
                    style: AppTypography.screenTitle.copyWith(
                      color: surface.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing4),
                  Text(
                    'Structured work and break cycles for healthy productivity.',
                    style: AppTypography.screenSubtitle.copyWith(
                      color: surface.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                  _TimerCard(
                    state: state,
                    progress: progress,
                    surface: surface,
                  ),
                  const SizedBox(height: AppConstants.spacing20),
                  _ControlRow(
                    state: state,
                    onStart: () => ref
                        .read(focusTimerProvider.notifier)
                        .startRun(goal: _goal, template: _template),
                    onPause: () =>
                        ref.read(focusTimerProvider.notifier).pauseRun(),
                    onResume: () =>
                        ref.read(focusTimerProvider.notifier).resumeRun(),
                    onStop: () =>
                        ref.read(focusTimerProvider.notifier).stopRun(),
                  ),
                  const SizedBox(height: AppConstants.spacing20),
                  _SummaryCard(
                    state: state,
                    goal: _goal,
                    template: _template,
                    surface: surface,
                  ),
                  const SizedBox(height: AppConstants.spacing20),
                  _HistoryCard(surface: surface),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final result = await showDialog<FocusTimerSettingsResult>(
      context: context,
      builder: (context) => FocusTimerSettingsDialog(
        initialGoal: _goal,
        initialTemplate: _template,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _goal = result.goal;
      _template = result.template;
    });
  }
}

final focusNotificationServiceProvider = Provider<FocusNotificationService>((
  ref,
) {
  return FocusNotificationService();
});

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.state,
    required this.progress,
    required this.surface,
  });

  final FocusRunStateEntity state;
  final double progress;
  final AppSurfaceTokens surface;

  String _phaseLabel(FocusRunPhase phase) {
    switch (phase) {
      case FocusRunPhase.idle:
        return 'Idle';
      case FocusRunPhase.focus:
        return 'Focus';
      case FocusRunPhase.shortBreak:
        return 'Short Break';
      case FocusRunPhase.longBreak:
        return 'Long Break';
      case FocusRunPhase.paused:
        return 'Paused';
      case FocusRunPhase.completed:
        return 'Completed';
    }
  }

  String _formatClock(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        color: surface.panel,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(color: surface.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.self_improvement, color: surface.accentStrong),
              const SizedBox(width: AppConstants.spacing8),
              Text(
                'Current Phase: ${_phaseLabel(state.phase)}',
                style: AppTypography.sectionTitle.copyWith(
                  color: surface.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            _formatClock(state.remainingSeconds),
            key: const Key('focus_timer_clock'),
            style: AppTextStyles.timerDisplay.copyWith(
              color: surface.textPrimary,
              fontSize: 72,
            ),
          ),
          const SizedBox(height: AppConstants.spacing16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: surface.panelHigh,
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'Progress ${(progress * 100).toStringAsFixed(1)}%',
            style: AppTypography.bodySmall.copyWith(
              color: surface.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final FocusRunStateEntity state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final canStart = !state.isActive && !state.isPaused;
    final canPause = state.isActive;
    final canResume = state.isPaused;
    final canStop = state.isActive || state.isPaused || state.isCompleted;

    return Wrap(
      spacing: AppConstants.spacing12,
      runSpacing: AppConstants.spacing12,
      children: [
        KeyedSubtree(
          key: const Key('focus_start_button'),
          child: AppButton.primary(
            label: 'Start',
            onPressed: canStart ? onStart : null,
            icon: Icons.play_arrow,
            minWidth: 120,
          ),
        ),
        KeyedSubtree(
          key: const Key('focus_pause_button'),
          child: AppButton.secondary(
            label: 'Pause',
            onPressed: canPause ? onPause : null,
            icon: Icons.pause,
            minWidth: 120,
          ),
        ),
        KeyedSubtree(
          key: const Key('focus_resume_button'),
          child: AppButton.secondary(
            label: 'Resume',
            onPressed: canResume ? onResume : null,
            icon: Icons.play_circle_outline,
            minWidth: 120,
          ),
        ),
        KeyedSubtree(
          key: const Key('focus_stop_button'),
          child: AppButton.danger(
            label: 'Stop',
            onPressed: canStop ? onStop : null,
            icon: Icons.stop,
            minWidth: 120,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.state,
    required this.goal,
    required this.template,
    required this.surface,
  });

  final FocusRunStateEntity state;
  final FocusGoalEntity goal;
  final FocusCycleTemplateEntity template;
  final AppSurfaceTokens surface;

  @override
  Widget build(BuildContext context) {
    final focusMinutes = (state.accumulatedFocusSeconds / 60).floor();
    final breakMinutes = (state.accumulatedBreakSeconds / 60).floor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: surface.panel,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(color: surface.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Summary',
            style: AppTypography.sectionTitle.copyWith(
              color: surface.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacing12),
          Text(
            'Goal: ${goal.targetFocusMinutes}m  |  Cycle: ${template.focusMinutes}/${template.shortBreakMinutes}  |  Long break every ${template.longBreakEveryNCycles}',
            style: AppTypography.body.copyWith(color: surface.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'Focused: ${focusMinutes}m  |  Breaks: ${breakMinutes}m  |  Cycles: ${state.completedFocusCycles}',
            style: AppTypography.body.copyWith(color: surface.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.surface});

  final AppSurfaceTokens surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(focusTimerHistoryProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: surface.panel,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(color: surface.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Focus Runs',
            style: AppTypography.sectionTitle.copyWith(
              color: surface.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacing12),
          historyAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Text(
                  'No runs yet. Start your first focus session.',
                  style: AppTypography.body.copyWith(
                    color: surface.textSecondary,
                  ),
                );
              }

              return Column(
                children: records.take(5).map((record) {
                  final started = record.startedAt.toLocal();
                  final status = record.completed ? 'Complete' : 'Stopped';
                  final focusMinutes = (record.actualFocusSeconds / 60).floor();
                  final breakMinutes = (record.actualBreakSeconds / 60).floor();

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacing8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${started.year}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')} ${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.bodySmall.copyWith(
                              color: surface.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '$focusMinutes m focus / $breakMinutes m break',
                          style: AppTypography.bodySmall.copyWith(
                            color: surface.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing8,
                            vertical: AppConstants.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: record.completed
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: AppTypography.bodySmall.copyWith(
                              color: record.completed
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'Unable to load history',
              style: AppTypography.body.copyWith(color: surface.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
