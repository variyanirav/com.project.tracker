import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_avatar.dart';

/// Project header displaying project name, title, and avatar
class ProjectHeader extends StatelessWidget {
  final String projectName;

  const ProjectHeader({super.key, required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.screenTitles.projectDetails,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 4),
            Text(projectName, style: AppTextStyles.bodyMedium),
          ],
        ),
        AppAvatar(
          initials: projectName.isEmpty ? 'P' : projectName[0].toUpperCase(),
        ),
      ],
    );
  }
}
