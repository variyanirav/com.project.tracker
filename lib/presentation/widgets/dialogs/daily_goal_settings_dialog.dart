import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';

/// Daily Goal Settings Dialog
class DailyGoalSettingsDialog extends StatefulWidget {
  final int currentGoalHours;
  final Function(int hours)? onSavePressed;

  const DailyGoalSettingsDialog({
    super.key,
    this.currentGoalHours = 8,
    this.onSavePressed,
  });

  @override
  State<DailyGoalSettingsDialog> createState() =>
      _DailyGoalSettingsDialogState();
}

class _DailyGoalSettingsDialogState extends State<DailyGoalSettingsDialog> {
  late int _selectedHours;

  @override
  void initState() {
    super.initState();
    _selectedHours = widget.currentGoalHours;
  }

  void _handleSave() {
    widget.onSavePressed?.call(_selectedHours);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Goal Settings', style: AppTextStyles.heading2),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing4),
            Text(
              'Set your daily tracking goal',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),

            SizedBox(height: AppConstants.spacing32),

            // Current Setting Display
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing24,
                vertical: AppConstants.spacing20,
              ),
              child: Column(
                children: [
                  Text(
                    'Current Daily Goal',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing12),
                  Text(
                    '$_selectedHours hours',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.spacing32),

            // Hour Selector with Slider
            Text('Select Hours', style: AppTextStyles.labelMedium),
            SizedBox(height: AppConstants.spacing16),
            Slider(
              value: _selectedHours.toDouble(),
              min: 1,
              max: 16,
              divisions: 15,
              label: '$_selectedHours hours',
              activeColor: AppColors.brandPrimary,
              inactiveColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              onChanged: (value) {
                setState(() {
                  _selectedHours = value.toInt();
                });
              },
            ),

            SizedBox(height: AppConstants.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1h',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                Text(
                  '16h',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing32),

            // Quick Select Buttons
            Text('Quick Select', style: AppTextStyles.labelMedium),
            SizedBox(height: AppConstants.spacing12),
            Wrap(
              spacing: AppConstants.spacing8,
              runSpacing: AppConstants.spacing8,
              children: [4, 6, 8, 10, 12].map((hours) {
                final isSelected = _selectedHours == hours;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedHours = hours;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing16,
                      vertical: AppConstants.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(
                        AppConstants.roundRadius,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '$hours hours',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: AppConstants.spacing32),

            // Info Text
            Container(
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.roundRadius),
              ),
              padding: EdgeInsets.all(AppConstants.spacing12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Text(
                      'Your daily goal helps you track productivity. You can change this anytime.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.spacing32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: AppConstants.spacing16),
                AppButton.primary(label: 'Save Goal', onPressed: _handleSave),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
