import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Application text styles - using system fonts (Roboto)
/// No internet required for font loading
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  static const String _fontFamily = 'Roboto'; // Built-in system font

  // ============ HEADING STYLES ============
  static TextStyle get heading1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeHeading1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeHeading2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  static TextStyle get headingLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeXXLarge,
    fontWeight: FontWeight.w600,
  );

  // ============ TITLE STYLES ============
  static TextStyle get titleLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeXLarge,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeLarge,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.w600,
  );

  // ============ BODY STYLES ============
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeBase,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeSmall,
    fontWeight: FontWeight.w400,
  );

  // ============ LABEL STYLES ============
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeBase,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeSmall,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ============ BUTTON STYLES ============
  static TextStyle get buttonLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get buttonMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeBase,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get buttonSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeSmall,
    fontWeight: FontWeight.w600,
  );

  // ============ SPECIAL STYLES ============
  static TextStyle get timerDisplay => const TextStyle(
    fontFamily: 'Courier New',
    fontSize: 64.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.0,
  );

  static TextStyle get timerSmall => const TextStyle(
    fontFamily: 'Courier New',
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get monospace => TextStyle(
    fontFamily: 'Courier New',
    fontSize: AppConstants.fontSizeBase,
    fontWeight: FontWeight.w500,
  );

  // ============ CAPTION & HELPER ============
  static TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeSmall,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get captionSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.fontSizeXSmall,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );
}
