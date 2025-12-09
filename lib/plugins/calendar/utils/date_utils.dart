import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:get/get.dart';

class CalendarDateUtils {
  /// 获取指定月份的所有日期
  static List<DateTime> getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysBefore = first.weekday % 7;
    final firstToDisplay = first.subtract(Duration(days: daysBefore));

    // 总共显示6周，确保日历网格填满
    final daysToGenerate = 42; // 6行 x 7列

    return List.generate(daysToGenerate, (index) {
      return firstToDisplay.add(Duration(days: index));
    });
  }

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断日期是否在当前月份
  static bool isInCurrentMonth(DateTime date, DateTime currentMonth) {
    return date.year == currentMonth.year && date.month == currentMonth.month;
  }

  /// 获取指定日期的所有事件
  static List<CalendarEvent> getEventsForDay(
    List<CalendarEvent> events,
    DateTime day,
  ) {
    return events.where((event) {
      // 检查是否是同一天
      final isSameStartDay = isSameDay(event.startTime, day);

      // 处理跨天事件
      final bool isMultiDayEvent =
          event.endTime != null && !isSameDay(event.startTime, event.endTime!);

      if (isMultiDayEvent) {
        // 检查day是否在事件的开始和结束日期之间
        return day.isAfter(event.startTime.subtract(const Duration(days: 1))) &&
            day.isBefore(event.endTime!.add(const Duration(days: 1)));
      }

      return isSameStartDay;
    }).toList();
  }

  /// 格式化时间显示
  static String formatTimeRange(DateTime start, DateTime? end) {
    final startFormat = '${_formatDate(start)} ${_formatTime(start)}';

    if (end == null) {
      return startFormat;
    }

    if (isSameDay(start, end)) {
      return '$startFormat - ${_formatTime(end)}';
    }

    return '$startFormat - ${_formatDate(end)} ${_formatTime(end)}';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  /// 格式化日期
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 格式化时间
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
