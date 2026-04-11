import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';

/// Sticky project header displaying project name, avatar, and primary action.
class ProjectHeader extends StatelessWidget {
  final String projectName;
  final VoidCallback onCreatePressed;

  const ProjectHeader({
    super.key,
    required this.projectName,
    required this.onCreatePressed,
  });

  String _projectInitials() {
    final trimmed = projectName.trim();
    if (trimmed.isEmpty) return 'PR';

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    final compact = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (compact.length >= 2) {
      return compact.substring(0, 2).toUpperCase();
    }

    return compact.padRight(2, 'P').substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          AppAvatar(initials: _projectInitials()),
          const SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.screenTitles.projectDetails,
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 4),
                Tooltip(
                  message: projectName,
                  child: Text(
                    projectName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacing16),
          AppButton.primary(
            label: 'Create New Task',
            icon: Icons.add,
            minWidth: AppConstants.topBarActionButtonMinWidth,
            onPressed: onCreatePressed,
          ),
        ],
      ),
    );
  }
}
