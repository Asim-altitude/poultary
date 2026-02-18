import '../models/enums.dart';

/// Date utility functions for the insights engine
class InsightsDateUtils {
  InsightsDateUtils._();

  /// Returns the start date for a given TimePeriod
  static DateTime startDateForPeriod(TimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case TimePeriod.last3Months:
        return now.subtract(const Duration(days: 90));
      case TimePeriod.last6Months:
        return now.subtract(const Duration(days: 180));
      case TimePeriod.last12Months:
        return now.subtract(const Duration(days: 365));
      case TimePeriod.thisYear:
        return DateTime(now.year, 1, 1);
    }
  }

  /// Returns the previous equivalent period start/end (for comparison)
  static ({DateTime start, DateTime end}) previousPeriod(TimePeriod period) {
    final currentStart = startDateForPeriod(period);
    final currentEnd = DateTime.now();
    final duration = currentEnd.difference(currentStart);
    return (
      start: currentStart.subtract(duration),
      end: currentStart.subtract(const Duration(days: 1)),
    );
  }

  /// Filter records within a date range
  static List<T> filterByDateRange<T>(
    List<T> records,
    DateTime Function(T) dateGetter,
    DateTime start,
    DateTime end,
  ) {
    return records.where((r) {
      final d = dateGetter(r);
      return d.isAfter(start.subtract(const Duration(days: 1))) &&
          d.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Group records by month
  static Map<String, List<T>> groupByMonth<T>(
    List<T> records,
    DateTime Function(T) dateGetter,
  ) {
    final map = <String, List<T>>{};
    for (final record in records) {
      final date = dateGetter(record);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(record);
    }
    return map;
  }

  /// Group records by week
  static Map<String, List<T>> groupByWeek<T>(
    List<T> records,
    DateTime Function(T) dateGetter,
  ) {
    final map = <String, List<T>>{};
    for (final record in records) {
      final date = dateGetter(record);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final key =
          '${weekStart.year}-W${_weekNumber(weekStart).toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(record);
    }
    return map;
  }

  /// Get ISO week number
  static int _weekNumber(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Returns true if a date is in the same month as today
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Get month name key (for localization)
  static String monthNameKey(int month) {
    const keys = [
      '',
      'month_january',
      'month_february',
      'month_march',
      'month_april',
      'month_may',
      'month_june',
      'month_july',
      'month_august',
      'month_september',
      'month_october',
      'month_november',
      'month_december',
    ];
    return keys[month.clamp(1, 12)];
  }

  /// Split records into equal halves for period-over-period comparison
  static ({List<T> first, List<T> second}) splitInHalf<T>(List<T> records) {
    final mid = records.length ~/ 2;
    return (
      first: records.sublist(0, mid),
      second: records.sublist(mid),
    );
  }

  /// Returns the last N days of records
  static List<T> lastNDays<T>(
    List<T> records,
    DateTime Function(T) dateGetter,
    int n,
  ) {
    final cutoff = DateTime.now().subtract(Duration(days: n));
    return records.where((r) => dateGetter(r).isAfter(cutoff)).toList();
  }

  /// Sort records by date ascending
  static List<T> sortByDate<T>(
    List<T> records,
    DateTime Function(T) dateGetter,
  ) {
    final sorted = List<T>.from(records);
    sorted.sort((a, b) => dateGetter(a).compareTo(dateGetter(b)));
    return sorted;
  }

  /// Format date as readable string (e.g. "Jan 15")
  static String formatShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
