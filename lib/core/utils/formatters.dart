import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Time and duration formatting utilities
class TimeFormatter {
  TimeFormatter._(); // Private constructor

  /// Format seconds to HH:MM:SS format
  /// Example: 3661 seconds → "01:01:01"
  static String secondsToTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format seconds to HHh MMm format (user-friendly)
  /// Example: 3661 seconds → "1h 1m"
  static String secondsToShortForm(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  /// Format seconds to decimal hours
  /// Example: 3600 seconds → 1.00 hours
  static String secondsToHours(int seconds, {int precision = 2}) {
    final hours = seconds / 3600;
    return hours.toStringAsFixed(precision);
  }

  /// Format seconds to HH:MM (for CSV export)
  /// Example: 5400 seconds → "1:30" (1 hour 30 minutes)
  static String secondsToHoursMinutes(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  /// Extract hours, minutes, seconds separately
  /// Returns Map with 'hours', 'minutes', 'seconds'
  static Map<String, int> breakdownSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    return {
      'hours': duration.inHours,
      'minutes': duration.inMinutes.remainder(60),
      'seconds': duration.inSeconds.remainder(60),
    };
  }
}

/// DateTime formatting utilities
class DateFormatter {
  DateFormatter._(); // Private constructor

  /// Format DateTime to yyyy-MM-dd
  static String toDate(DateTime dateTime) {
    return DateFormat(AppConstants.dateFormat).format(dateTime);
  }

  /// Format DateTime to HH:mm:ss
  static String toTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  /// Format DateTime to yyyy-MM-dd HH:mm:ss
  static String toDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  /// Format DateTime to human-readable format
  /// Example: "March 19, 2026"
  static String toHumanReadable(DateTime dateTime) {
    return DateFormat('MMMM dd, yyyy').format(dateTime);
  }

  /// Format DateTime to relative time
  /// Example: "2 hours ago", "Today at 2:30 PM"
  static String toRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return toHumanReadable(dateTime);
    }
  }

  /// Get week number from date
  static int getWeekNumber(DateTime date) {
    final jan4 = DateTime(date.year, 1, 4);
    final startWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
    final diff = date.difference(startWeek).inDays;
    return (diff / 7).ceil();
  }

  /// Get start of week (Monday)
  static DateTime getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Get end of week (Sunday)
  static DateTime getWeekEnd(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  /// Get start of month
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}

/// Number formatting utilities
class NumberFormatter {
  NumberFormatter._(); // Private constructor

  /// Format number to currency (USD)
  static String toCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return formatter.format(amount);
  }

  /// Format number with decimal places
  static String toDecimal(double number, {int places = 2}) {
    return number.toStringAsFixed(places);
  }

  /// Format large numbers with commas
  /// Example: 1000 → "1,000"
  static String toThousands(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Format percentage
  /// Example: 0.85 → "85%"
  static String toPercentage(double value, {int decimals = 0}) {
    final percentage = (value * 100).toStringAsFixed(decimals);
    return '$percentage%';
  }
}
