import 'package:flutter/material.dart';
import 'dart:async';

import '../constants/app_constants.dart';
import '../theme/text_styles.dart';
import 'app_button.dart';

/// Reusable confirmation dialog with Yes/No actions.
class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final FutureOr<void> Function() onConfirmPressed;
  final IconData? icon;
  final Color? iconColor;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirmPressed,
    this.confirmLabel = 'Yes',
    this.cancelLabel = 'No',
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacing32,
                horizontal: AppConstants.spacing24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: resolvedIconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: resolvedIconColor, size: 32),
                    ),
                    SizedBox(height: AppConstants.spacing24),
                  ],
                  Text(title, style: AppTextStyles.heading2),
                  SizedBox(height: AppConstants.spacing12),
                  Text(message, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.secondary(
                    label: cancelLabel,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  AppButton.danger(
                    label: confirmLabel,
                    onPressed: () async {
                      await onConfirmPressed();
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
