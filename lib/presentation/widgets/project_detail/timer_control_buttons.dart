import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';

/// Timer control buttons (Pause/Start and Stop)
class TimerControlButtons extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPauseStartPressed;
  final VoidCallback onStopPressed;

  const TimerControlButtons({
    super.key,
    required this.isPaused,
    required this.onPauseStartPressed,
    required this.onStopPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton.primary(
            label: isPaused
                ? AppStrings.buttons.start
                : AppStrings.buttons.pauseTimer,
            onPressed: onPauseStartPressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton.danger(
            label: AppStrings.buttons.stopTimer,
            onPressed: onStopPressed,
          ),
        ),
      ],
    );
  }
}
