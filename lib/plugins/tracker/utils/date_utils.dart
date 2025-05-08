
class DateUtils {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isDateInRange(DateTime date, DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return (date.isAfter(start) || isSameDay(date, start)) &&
        (date.isBefore(end) || isSameDay(date, end));
  }

  static bool isDayOfWeek(DateTime date, String dayName) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final index = weekdays.indexOf(dayName);
    if (index == -1) return false;
    
    // 周一=1, 周日=7 in DateTime.weekday
    return date.weekday == index + 1;
  }

  static bool isDayOfMonth(DateTime date, int day) {
    return date.day == day;
  }
}
