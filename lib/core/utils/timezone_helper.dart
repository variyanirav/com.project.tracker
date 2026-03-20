import 'package:intl/intl.dart';

/// Timezone conversion and formatting utilities
/// All database timestamps are stored in UTC for consistency
/// Display conversions happen at the presentation layer
class TimezoneHelper {
  TimezoneHelper._(); // Private constructor - static only

  /// Get current UTC DateTime
  static DateTime getCurrentUtc() {
    return DateTime.now().toUtc();
  }

  /// Get current local DateTime
  static DateTime getCurrentLocal() {
    return DateTime.now();
  }

  /// Convert local DateTime to UTC for database storage
  static DateTime toUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Convert UTC DateTime to local for display
  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Get the start of today in UTC (00:00:00 UTC)
  static DateTime getTodayStartUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Get the start of today in local timezone (00:00:00)
  static DateTime getTodayStartLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get the end of today in UTC (23:59:59 UTC)
  static DateTime getTodayEndUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Get the end of today in local timezone
  static DateTime getTodayEndLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Get the start of the week (Monday) in UTC
  /// weekStart is Monday (1-7, where 1=Monday, 7=Sunday)
  static DateTime getWeekStartUtc({DateTime? referenceDate}) {
    final ref = (referenceDate ?? DateTime.now()).toUtc();
    final daysToMonday = (ref.weekday - 1) % 7;
    return DateTime.utc(ref.year, ref.month, ref.day - daysToMonday);
  }

  /// Get the start of the week (Monday) in local timezone
  static DateTime getWeekStartLocal({DateTime? referenceDate}) {
    final ref = referenceDate ?? DateTime.now();
    final daysToMonday = (ref.weekday - 1) % 7;
    return DateTime(ref.year, ref.month, ref.day - daysToMonday);
  }

  /// Get the end of the week (Sunday) in UTC
  static DateTime getWeekEndUtc({DateTime? referenceDate}) {
    final weekStart = getWeekStartUtc(referenceDate: referenceDate);
    return weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  /// Get the end of the week (Sunday) in local timezone
  static DateTime getWeekEndLocal({DateTime? referenceDate}) {
    final weekStart = getWeekStartLocal(referenceDate: referenceDate);
    return weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  /// Format DateTime for display (e.g., "Mar 20, 2026 2:30 PM")
  static String formatForDisplay(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final formatter = DateFormat('MMM d, yyyy h:mm a');
    return formatter.format(local);
  }

  /// Format DateTime as date only (e.g., "March 20, 2026")
  static String formatDateOnly(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final formatter = DateFormat('MMMM d, yyyy');
    return formatter.format(local);
  }

  /// Format DateTime as time only (e.g., "2:30 PM")
  static String formatTimeOnly(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final formatter = DateFormat('h:mm a');
    return formatter.format(local);
  }

  /// Format DateTime as ISO 8601 string for storage/transfer
  static String formatIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parse ISO 8601 string to DateTime
  static DateTime parseIso8601(String isoString) {
    return DateTime.parse(isoString);
  }

  /// Check if a UTC timestamp occurred today
  static bool isToday(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  /// Check if a UTC timestamp occurred this week
  static bool isThisWeek(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final weekStart = getWeekStartLocal();
    final weekEnd = getWeekEndLocal();
    return local.isAfter(weekStart) && local.isBefore(weekEnd);
  }

  /// Get the difference in days between two dates (ignoring time)
  static int daysDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inDays.abs();
  }

  /// Check if two dates are the same day (timezone-ignorant)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
