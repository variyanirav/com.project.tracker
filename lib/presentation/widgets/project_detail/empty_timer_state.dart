import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';

/// Empty state displayed when no timer is active
class EmptyTimerState extends StatelessWidget {
  final bool isDark;

  const EmptyTimerState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurfaceTokens(isDark: isDark);

    return AppCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: surface.panel,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 48, color: AppColors.brandPrimary),
            const SizedBox(height: 16),
            Text(
              AppStrings.labels.noActiveTimer,
              style: AppTypography.sectionTitle.copyWith(
                color: surface.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.messages.startTimerInstructions,
              style: AppTypography.body.copyWith(color: surface.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
