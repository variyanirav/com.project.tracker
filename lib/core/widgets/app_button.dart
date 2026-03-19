import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';

/// Reusable button widget with multiple variants
/// Supports primary, secondary, danger, and ghost styles
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isFullWidth = false,
    this.padding,
    this.minWidth,
  });

  /// Factory constructor for primary button variant
  factory AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? minWidth,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      variant: ButtonVariant.primary,
      size: size,
      icon: icon,
      isFullWidth: isFullWidth,
      padding: padding,
      minWidth: minWidth,
    );
  }

  /// Factory constructor for secondary button variant
  factory AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? minWidth,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      variant: ButtonVariant.secondary,
      size: size,
      icon: icon,
      isFullWidth: isFullWidth,
      padding: padding,
      minWidth: minWidth,
    );
  }

  /// Factory constructor for danger button variant
  factory AppButton.danger({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? minWidth,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      variant: ButtonVariant.danger,
      size: size,
      icon: icon,
      isFullWidth: isFullWidth,
      padding: padding,
      minWidth: minWidth,
    );
  }

  /// Factory constructor for ghost button variant
  factory AppButton.ghost({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isFullWidth = false,
    EdgeInsetsGeometry? padding,
    double? minWidth,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      variant: ButtonVariant.ghost,
      size: size,
      icon: icon,
      isFullWidth: isFullWidth,
      padding: padding,
      minWidth: minWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(isDark),
    );
  }

  Widget _buildButton(bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading || !isEnabled ? null : onPressed,
          child: _buildContent(),
        );
      case ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading || !isEnabled ? null : onPressed,
          child: _buildContent(),
        );
      case ButtonVariant.danger:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withOpacity(0.5),
          ),
          onPressed: isLoading || !isEnabled ? null : onPressed,
          child: _buildContent(),
        );
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading || !isEnabled ? null : onPressed,
          child: _buildContent(),
        );
    }
  }

  Widget _buildContent() {
    final textWidget = Text(label);

    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          SizedBox(width: AppConstants.spacing8),
          textWidget,
        ],
      );
    }

    return textWidget;
  }
}

enum ButtonVariant { primary, secondary, danger, ghost }

enum ButtonSize { small, medium, large }
