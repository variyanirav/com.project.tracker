import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Reusable card widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = AppSurfaceTokens(isDark: isDark);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor ?? tokens.panel,
            border: Border.all(color: borderColor ?? tokens.border, width: 1),
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            boxShadow: elevation != null && elevation! > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.22 : 0.08,
                      ),
                      blurRadius: elevation ?? 2,
                      offset: Offset(0, elevation ?? 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
