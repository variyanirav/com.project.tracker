import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';

class ReportsPalette {
  ReportsPalette({required this.isDark})
    : _surface = AppSurfaceTokens(isDark: isDark);

  final bool isDark;
  final AppSurfaceTokens _surface;

  Color get page => _surface.page;
  Color get section => _surface.panel;
  Color get panel => _surface.panel;
  Color get panelHigh => _surface.panelHigh;
  Color get panelLowest => _surface.panelLowest;
  Color get textPrimary => _surface.textPrimary;
  Color get textSecondary => _surface.textSecondary;
  Color get textMuted => _surface.textMuted;
  Color get accent => _surface.accent;
  Color get accentStrong => _surface.accentStrong;
  Color get tableHeader => _surface.tableHeader;
  Color get subtleBorder => _surface.border;
}

class ReportsPanel extends StatelessWidget {
  const ReportsPanel({
    super.key,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final ReportsPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.subtleBorder),
      ),
      child: child,
    );
  }
}

class ReportsMetricCard extends StatelessWidget {
  const ReportsMetricCard({
    super.key,
    required this.palette,
    required this.title,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.iconColor,
  });

  final ReportsPalette palette;
  final String title;
  final String value;
  final String suffix;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTypography.metricValue.copyWith(
                color: palette.textPrimary,
              ),
              children: [
                TextSpan(
                  text: suffix,
                  style: AppTypography.metricSuffix.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsActionButton extends StatelessWidget {
  const ReportsActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.palette,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final ReportsPalette palette;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: primary ? null : Border.all(color: palette.subtleBorder),
            color: primary
                ? null
                : (canTap ? palette.panelLowest : palette.panelHigh),
            gradient: primary
                ? LinearGradient(
                    colors: [palette.accent, palette.accentStrong],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: primary
                    ? (palette.isDark ? const Color(0xFF002E69) : Colors.white)
                    : (canTap ? palette.textSecondary : palette.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.actionLabel.copyWith(
                  color: primary
                      ? (palette.isDark
                            ? const Color(0xFF002E69)
                            : Colors.white)
                      : (canTap ? palette.textPrimary : palette.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration reportsInputDecoration({
  required ReportsPalette palette,
  required String label,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: AppTypography.label.copyWith(color: palette.textMuted),
    filled: true,
    fillColor: palette.panelLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: palette.subtleBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: palette.subtleBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.8)),
    ),
  );
}
