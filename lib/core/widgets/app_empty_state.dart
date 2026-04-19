import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/text_styles.dart';

/// Shared empty-state component for consistent no-data experiences.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = AppSurfaceTokens(isDark: isDark);
    final resolvedIconColor = iconColor ?? tokens.accent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: resolvedIconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.helper.copyWith(color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
