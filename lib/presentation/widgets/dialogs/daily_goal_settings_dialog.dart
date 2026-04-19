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
    final surface = AppSurfaceTokens(isDark: isDark);

    return Dialog(
      backgroundColor: surface.panel,
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
                Text(
                  'Daily Goal Settings',
                  style: AppTypography.sectionTitle.copyWith(
                    color: surface.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing4),
            Text(
              'Set your daily tracking goal',
              style: AppTypography.bodySmall.copyWith(
                color: surface.textSecondary,
              ),
            ),

            SizedBox(height: AppConstants.spacing32),

            // Current Setting Display
            Container(
              decoration: BoxDecoration(
                color: surface.panelHigh,
                borderRadius: BorderRadius.circular(AppConstants.roundRadius),
                border: Border.all(color: surface.border),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing24,
                vertical: AppConstants.spacing20,
              ),
              child: Column(
                children: [
                  Text(
                    'Current Daily Goal',
                    style: AppTypography.label.copyWith(
                      color: surface.textSecondary,
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
            Text(
              'Select Hours',
              style: AppTypography.actionLabel.copyWith(
                color: surface.textPrimary,
              ),
            ),
            SizedBox(height: AppConstants.spacing16),
            Slider(
              value: _selectedHours.toDouble(),
              min: 1,
              max: 16,
              divisions: 15,
              label: '$_selectedHours hours',
              activeColor: AppColors.brandPrimary,
              inactiveColor: isDark ? surface.border : surface.border,
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
                  style: AppTypography.label.copyWith(color: surface.textMuted),
                ),
                Text(
                  '16h',
                  style: AppTypography.label.copyWith(color: surface.textMuted),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing32),

            // Quick Select Buttons
            Text(
              'Quick Select',
              style: AppTypography.actionLabel.copyWith(
                color: surface.textPrimary,
              ),
            ),
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
                          : surface.panelHigh,
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
                      style: AppTypography.label.copyWith(
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
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.spacing12),
            Center(
              child: Text(
                'App Version ${AppConstants.appVersion}',
                style: AppTypography.label.copyWith(color: surface.textMuted),
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
