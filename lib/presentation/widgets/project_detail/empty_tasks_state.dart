import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_empty_state.dart';

/// Empty state displayed when no tasks exist
class EmptyTasksState extends StatelessWidget {
  const EmptyTasksState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.task_outlined,
      title: AppStrings.messages.noRecordsFound,
      message: AppStrings.messages.createFirstTaskInstructions,
      iconColor: AppColors.brandPrimary,
    );
  }
}
