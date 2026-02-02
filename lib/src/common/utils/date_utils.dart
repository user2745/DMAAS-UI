import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfWeek(DateTime date) {
    final normalized = normalizeDate(date);
    final weekday = normalized.weekday % 7; // Sunday = 0
    return normalized.subtract(Duration(days: weekday));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static int daysInMonth(DateTime date) {
    final firstOfNextMonth = DateTime(date.year, date.month + 1, 1);
    final lastOfMonth = firstOfNextMonth.subtract(const Duration(days: 1));
    return lastOfMonth.day;
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  static String formatDayNumber(DateTime date) {
    return DateFormat('d').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mma').format(date).toLowerCase();
  }

  static bool hasTimeComponent(DateTime date) {
    return date.hour != 0 || date.minute != 0 || date.second != 0;
  }

  static int daysBetween(DateTime start, DateTime end) {
    final s = normalizeDate(start);
    final e = normalizeDate(end);
    return e.difference(s).inDays;
  }
}
