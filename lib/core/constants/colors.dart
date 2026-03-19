import 'package:flutter/material.dart';

/// Application color palette
/// Following dark-first design philosophy with brand blue accents
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============ DARK THEME COLORS ============
  static const Color darkBg = Color(0xFF0B111D); // #0B111D - Navy Background
  static const Color darkSurface = Color(0xFF151C2C); // #151C2C - Dark Surface
  static const Color darkCard = Color(0xFF1F2937); // #1F2937 - Card Background

  // ============ LIGHT THEME COLORS ============
  static const Color lightBg = Color(0xFFF9FAFB); // #F9FAFB - Off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // #FFFFFF - White
  static const Color lightCard = Color(0xFFF3F4F6); // #F3F4F6 - Light gray

  // ============ BRAND COLORS ============
  static const Color brandPrimary = Color(0xFF007BFF); // #007BFF - Brand Blue
  static const Color brandDark = Color(0xFF0056B3); // #0056B3 - Darker Blue
  static const Color brandLight = Color(0xFF3395FF); // #3395FF - Lighter Blue

  // ============ BORDER & DIVIDER COLORS ============
  static const Color darkBorder = Color(0xFF334155); // #334155 - Gray border
  static const Color lightBorder = Color(0xFFE5E7EB); // #E5E7EB - Light border

  // ============ TEXT COLORS ============
  static const Color darkTextPrimary = Color(
    0xFFF9FAFB,
  ); // #F9FAFB - Primary text
  static const Color darkTextSecondary = Color(
    0xFF9CA3AF,
  ); // #9CA3AF - Secondary text
  static const Color darkTextTertiary = Color(
    0xFF6B7280,
  ); // #6B7280 - Tertiary text

  static const Color lightTextPrimary = Color(
    0xFF111827,
  ); // #111827 - Primary text
  static const Color lightTextSecondary = Color(
    0xFF6B7280,
  ); // #6B7280 - Secondary text
  static const Color lightTextTertiary = Color(
    0xFF9CA3AF,
  ); // #9CA3AF - Tertiary text

  // ============ STATUS COLORS ============
  static const Color success = Color(0xFF10B981); // #10B981 - Green
  static const Color warning = Color(0xFFF59E0B); // #F59E0B - Amber
  static const Color error = Color(0xFFEF4444); // #EF4444 - Red
  static const Color info = Color(0xFF3B82F6); // #3B82F6 - Blue

  // ============ PROJECT COLORS (Variants) ============
  static const List<Color> projectColors = [
    Color(0xFF007BFF), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFD946EF), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF06B6D4), // Cyan
  ];
}
