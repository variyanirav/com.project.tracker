import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';

/// Empty state displayed when no tasks exist
class EmptyTasksState extends StatelessWidget {
  const EmptyTasksState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.task_outlined, size: 48, color: AppColors.brandPrimary),
            const SizedBox(height: 16),
            Text(AppStrings.messages.noTasksYet, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              AppStrings.messages.createFirstTaskInstructions,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
