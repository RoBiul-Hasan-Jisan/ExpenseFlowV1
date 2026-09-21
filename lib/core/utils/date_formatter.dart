import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String monthDay(DateTime d) => DateFormat('MMM d').format(d);
  static String monthDayYear(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  static String fullMonth(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String weekdayShort(DateTime d) => DateFormat('EEE').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  static String relative(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return '$diff days ago';
    if (diff < -1 && diff > -7) return 'In ${-diff} days';
    return monthDay(d);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
