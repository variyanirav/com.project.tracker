/// Date and time formatting utilities
/// Provides consistent formatting across the application
class DateTimeFormatter {
  /// Format hours (double) to readable format like "12h 45m"
  static String formatHours(double hours) {
    if (hours == 0) return '0m';

    final wholeHours = hours.toInt();
    final minutes = ((hours - wholeHours) * 60).toInt();

    if (wholeHours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${wholeHours}h';
    }
    return '${wholeHours}h ${minutes}m';
  }

  /// Format elapsed time in seconds to HH:MM:SS format
  static String formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format seconds to readable format like "2h 30m"
  static String formatSeconds(int seconds) {
    if (seconds == 0) return '0m';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  /// Format date to readable format like "20th Mar 2026"
  static String formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day;
    final monthName = months[date.month];
    final year = date.year;
    final suffix = _getDayOfMonthSuffix(day);

    return '$day$suffix $monthName $year';
  }

  /// Get day of month suffix (st, nd, rd, th)
  static String _getDayOfMonthSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
