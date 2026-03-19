import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';

/// Confirm Delete Dialog
/// Shows a confirmation dialog before deleting a project or task
class ConfirmDeleteDialog extends StatelessWidget {
  final String itemName;
  final String itemType; // 'project' or 'task'
  final VoidCallback onConfirmPressed;
  final String? description;

  const ConfirmDeleteDialog({
    super.key,
    required this.itemName,
    required this.itemType,
    required this.onConfirmPressed,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon & Header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacing32,
                horizontal: AppConstants.spacing24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing24),

                  // Title
                  Text(
                    'Delete ${itemType.toUpperCase()}?',
                    style: AppTextStyles.heading2,
                  ),
                  SizedBox(height: AppConstants.spacing12),

                  // Description
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium,
                      children: [
                        const TextSpan(
                          text: 'Are you sure you want to delete ',
                        ),
                        TextSpan(
                          text: '"$itemName"',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: '? This action cannot be undone.'),
                      ],
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: AppConstants.spacing12),
                    Text(
                      description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(height: 1),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  AppButton(
                    label: 'Delete',
                    variant: ButtonVariant.danger,
                    onPressed: () {
                      onConfirmPressed();
                      Navigator.of(context).pop();
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
