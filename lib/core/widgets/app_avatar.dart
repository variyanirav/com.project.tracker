import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/text_styles.dart';

/// Avatar widget showing initials or image
class AppAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const AppAvatar({
    super.key,
    required this.initials,
    this.size = 40.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = AppSurfaceTokens(isDark: isDark);
    final bgColor = backgroundColor ?? tokens.accent;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor.withValues(alpha: 0.2),
      child: Text(
        initials,
        style: AppTypography.actionLabel.copyWith(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: bgColor,
        ),
      ),
    );
  }
}
