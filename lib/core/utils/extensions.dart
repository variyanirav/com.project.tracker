// Dart extensions for common operations
library;

import 'dart:math';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// String extensions
extension StringExtensions on String {
  /// Check if string is empty or null
  bool get isEmpty => this == '';

  /// Check if string is not empty
  bool get isNotEmpty => this != '';

  /// Capitalize first letter
  /// Example: "hello" → "Hello"
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Generate UUID from string (for IDs)
  /// Returns a UUID based on this string
  String toUUID() {
    return _uuid.v5(Uuid.NAMESPACE_DNS, this);
  }

  /// Check if string contains only alphanumeric characters
  bool get isAlphaNumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// Check if string is a valid URL
  bool get isValidUrl {
    return RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)$',
    ).hasMatch(this);
  }

  /// Truncate string to specified length with ellipsis
  /// Example: "Hello World".truncate(5) → "He..."
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }
}

/// Integer extensions
extension IntExtensions on int {
  /// Check if number is positive
  bool get isPositive => this > 0;

  /// Check if number is negative
  bool get isNegative => this < 0;

  /// Check if number is zero
  bool get isZero => this == 0;

  /// Convert to formatted string with leading zeros
  String padZero(int width) => toString().padLeft(width, '0');

  /// Check if number is even
  bool get isEven => this % 2 == 0;

  /// Check if number is odd
  bool get isOdd => this % 2 != 0;

  /// Convert milliseconds to Duration
  Duration get milliseconds => Duration(milliseconds: this);

  /// Convert seconds to Duration
  Duration get seconds => Duration(seconds: this);

  /// Convert minutes to Duration
  Duration get minutes => Duration(minutes: this);

  /// Convert hours to Duration
  Duration get hours => Duration(hours: this);

  /// Convert days to Duration
  Duration get days => Duration(days: this);
}

/// Double extensions
extension DoubleExtensions on double {
  /// Check if double is positive
  bool get isPositive => this > 0;

  /// Check if double is negative
  bool get isNegative => this < 0;

  /// Check if double is zero
  bool get isZero => this == 0.0;

  /// Round to specified decimal places
  double roundTo(int places) {
    final factor = pow(10.0, places).toInt();
    return (this * factor).round() / factor;
  }

  /// Convert to percentage string
  /// Example: 0.85.toPercentage() → "85%"
  String toPercentage({int decimals = 0}) {
    final percentage = (this * 100).toStringAsFixed(decimals);
    return '$percentage%';
  }
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Convert Duration to HH:MM:SS format
  String toTimeString() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Convert Duration to short format (1h 30m)
  String toShortString() {
    if (inHours == 0) {
      return '${inMinutes}m';
    } else if (inMinutes.remainder(60) == 0) {
      return '${inHours}h';
    } else {
      final minutes = inMinutes.remainder(60);
      return '${inHours}h ${minutes}m';
    }
  }

  /// Get hours as double
  double get inDecimalHours => inSeconds / 3600.0;

  /// Total hours and minutes
  /// Returns Map with 'hours' and 'minutes'
  Map<String, int> get breakdown {
    return {
      'hours': inHours,
      'minutes': inMinutes.remainder(60),
      'seconds': inSeconds.remainder(60),
    };
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get start of day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0);

  /// Get start of week (Monday)
  DateTime get startOfWeek => subtract(Duration(days: weekday - 1));

  /// Get end of week (Sunday)
  DateTime get endOfWeek => add(Duration(days: 7 - weekday));

  /// Get start of year
  DateTime get startOfYear => DateTime(year, 1, 1);

  /// Get end of year
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59);

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get difference in days from now
  int get daysFromNow {
    final now = DateTime.now();
    return difference(now).inDays;
  }

  /// Get difference in hours from now
  int get hoursFromNow {
    final now = DateTime.now();
    return difference(now).inHours;
  }

  /// Get week number in year
  int get weekNumber {
    final jan4 = DateTime(year, 1, 4);
    final startWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
    final diff = difference(startWeek).inDays;
    return (diff / 7).ceil();
  }

  /// Check if date is same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Get date as YYYY-MM-DD string
  String toDateString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// Copy with new values
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Check if list is not empty
  bool get isNotEmpty => this.isNotEmpty;

  /// Get element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Find element or return null (type-safe firstWhere)
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// Remove duplicates from list
  List<T> get unique => toSet().toList();

  /// Get multiple elements starting from index
  List<T> getRange(int start, int end) {
    if (start < 0) start = 0;
    if (end > length) end = length;
    if (start >= end) return [];
    return sublist(start, end);
  }
}

/// Map extensions
extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or return default
  V? getOrDefault(K key, [V? defaultValue]) {
    return this[key] ?? defaultValue;
  }

  /// Check if all keys exist
  bool hasKeys(List<K> keys) {
    return keys.every((key) => containsKey(key));
  }

  /// Get as string, handling nulls
  String toQueryString() {
    return entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key.toString())}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }
}
