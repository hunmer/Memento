/// 日历插件 - 公共小组件数据提供者
library;

import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';

/// 提供公共小组件的数据
class CalendarCommandWidgetsProvider {
  /// 获取公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> data,
  ) async {
    final plugin =
        PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
    if (plugin == null) return {};

    final controller = plugin.controller;
    final allEvents = controller.getAllEvents();
    final now = DateTime.now();

    return {
      // 事件日历小组件
      'eventCalendarWidget': _buildEventCalendarData(allEvents, now),

      // 每日事件卡片小组件
      'dailyEventsCard': _buildDailyEventsData(allEvents, now),

      // 每日日程卡片小组件
      'dailyScheduleCard': _buildDailyScheduleData(allEvents, now),

      // 时间线日程卡片小组件
      'timelineScheduleCard': _buildTimelineScheduleData(allEvents, now),
    };
  }

  /// 构建 EventCalendarWidget 数据
  static Map<String, dynamic> _buildEventCalendarData(
    List<CalendarEvent> events,
    DateTime now,
  ) {
    // 构建周历日期（本周7天）
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekDates = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      return date.day;
    });

    // 转换事件数据
    final widgetEvents =
        events.take(3).map((event) {
          return {
            'title': event.title,
            'time': DateFormat('h:mm').format(event.startTime),
            'duration': _formatDuration(event.startTime, event.endTime),
            'location': event.description.isNotEmpty ? event.description : null,
            'color': event.color.value,
            'iconColor': event.color.withOpacity(0.6).value,
            'buttonLabel': null,
          };
        }).toList();

    return {
      'day': now.day,
      'weekday': DateFormat('EEEE').format(now),
      'month': DateFormat('MMMM').format(now),
      'eventCount': events.length,
      'weekDates': weekDates,
      'weekStartDay': 0, // 周日为第一天
      'reminder': _getReminderText(events.length),
      'reminderEmoji': _getReminderEmoji(events.length),
      'events': widgetEvents,
    };
  }

  /// 构建 DailyEventsCard 数据
  static Map<String, dynamic> _buildDailyEventsData(
    List<CalendarEvent> events,
    DateTime now,
  ) {
    // 获取今天的事件
    final today = DateTime(now.year, now.month, now.day);
    final todayEvents =
        events.where((event) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          return eventDate.isAtSameMomentAs(today);
        }).toList();

    // 转换为 DailyEventData 格式
    final eventList =
        todayEvents.take(4).map((event) {
          final timeStr = DateFormat('h:mma').format(event.startTime);
          return {
            'title': event.title,
            'time': timeStr,
            'colorValue': event.color.value,
            'backgroundColorLightValue': _getLightBackground(event.color).value,
            'backgroundColorDarkValue': _getDarkBackground(event.color).value,
            'textColorLightValue': _getLightTextColor(event.color).value,
            'textColorDarkValue': _getDarkTextColor(event.color).value,
            'subtextLightValue': _getLightSubtext(event.color).value,
            'subtextDarkValue': _getDarkSubtext(event.color).value,
          };
        }).toList();

    return {
      'weekday': DateFormat('EEEE').format(now),
      'day': now.day,
      'events': eventList,
    };
  }

  /// 构建 DailyScheduleCard 数据
  static Map<String, dynamic> _buildDailyScheduleData(
    List<CalendarEvent> events,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 获取今天的事件
    final todayEvents =
        events
            .where((event) {
              final eventDate = DateTime(
                event.startTime.year,
                event.startTime.month,
                event.startTime.day,
              );
              return eventDate.isAtSameMomentAs(today);
            })
            .map((event) => _convertToScheduleEventData(event))
            .toList();

    // 获取明天的事件
    final tomorrowEvents =
        events
            .where((event) {
              final eventDate = DateTime(
                event.startTime.year,
                event.startTime.month,
                event.startTime.day,
              );
              return eventDate.isAtSameMomentAs(tomorrow);
            })
            .map((event) => _convertToScheduleEventData(event))
            .toList();

    return {
      'todayDate': DateFormat('MMMM d, yyyy').format(now),
      'todayEvents': todayEvents,
      'tomorrowEvents': tomorrowEvents,
    };
  }

  /// 构建 TimelineScheduleCard 数据
  static Map<String, dynamic> _buildTimelineScheduleData(
    List<CalendarEvent> events,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 获取今天的中文星期
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final todayWeekday = weekdayNames[today.weekday - 1];
    final tomorrowWeekday = weekdayNames[tomorrow.weekday - 1];

    // 获取今天的事件（按小时分组）
    final todayEvents =
        events
            .where((event) {
              final eventDate = DateTime(
                event.startTime.year,
                event.startTime.month,
                event.startTime.day,
              );
              return eventDate.isAtSameMomentAs(today);
            })
            .map((event) => _convertToTimelineEventData(event))
            .toList();

    // 获取明天的事件
    final tomorrowEvents =
        events
            .where((event) {
              final eventDate = DateTime(
                event.startTime.year,
                event.startTime.month,
                event.startTime.day,
              );
              return eventDate.isAtSameMomentAs(tomorrow);
            })
            .map((event) => _convertToTimelineEventData(event))
            .toList();

    return {
      'todayWeekday': '星期$todayWeekday',
      'todayDay': today.day,
      'tomorrowWeekday': '星期$tomorrowWeekday',
      'tomorrowDay': tomorrow.day,
      'todayEvents': todayEvents,
      'tomorrowEvents': tomorrowEvents,
    };
  }

  /// 转换为 DailyScheduleCard 的 EventData 格式
  static Map<String, dynamic> _convertToScheduleEventData(CalendarEvent event) {
    final startTime = DateFormat.jm().format(event.startTime);
    final endTime =
        event.endTime != null ? DateFormat.jm().format(event.endTime!) : '';

    // 解析时间字符串以分离时间和 AM/PM
    final startParts = startTime.split(' ');
    final startHour = startParts[0];
    final startPeriod = startParts.length > 1 ? startParts[1] : '';

    final endParts = endTime.split(' ');
    final endHour = endParts.isNotEmpty ? endParts[0] : '';
    final endPeriod = endParts.length > 1 ? endParts[1] : '';

    // 判断颜色类型
    final colorValue = event.color.value;

    return {
      'title': event.title,
      'startTime': startHour,
      'startPeriod': startPeriod,
      'endTime': endHour,
      'endPeriod': endPeriod,
      'color': _mapToEventColorName(colorValue),
      'location': event.description.isNotEmpty ? event.description : null,
      'isAllDay': false,
      'iconCodePoint': event.icon.codePoint,
    };
  }

  /// 转换为 TimelineScheduleCard 的 TimelineEvent 格式
  static Map<String, dynamic> _convertToTimelineEventData(CalendarEvent event) {
    final timeStr = DateFormat('h:mma').format(event.startTime);
    final hour = event.startTime.hour;

    return {
      'hour': hour,
      'title': event.title,
      'time': timeStr,
      'color': event.color.value,
      'backgroundColorLight': _getLightBackground(event.color).value,
      'backgroundColorDark': _getDarkBackground(event.color).value,
      'textColorLight': _getLightTextColor(event.color).value,
      'textColorDark': _getDarkTextColor(event.color).value,
      'subtextLight': _getLightSubtext(event.color).value,
      'subtextDark': _getDarkSubtext(event.color).value,
    };
  }

  /// 获取提醒文本
  static String _getReminderText(int eventCount) {
    if (eventCount == 0) return '今日暂无活动';
    if (eventCount == 1) return '您有 1 个活动';
    return '您有 $eventCount 个活动';
  }

  /// 获取提醒表情符号
  static String _getReminderEmoji(int eventCount) {
    if (eventCount == 0) return '📭';
    if (eventCount <= 2) return '📅';
    if (eventCount <= 5) return '📊';
    return '🔥';
  }

  /// 格式化持续时间
  static String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return '1h';
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// 将颜色值映射到 EventColor 枚举名称
  static String _mapToEventColorName(int colorValue) {
    // 简单的颜色映射逻辑
    final red = const Color(0xFFD35B5B);
    final green = const Color(0xFF10B981);
    final blue = const Color(0xFF3B82F6);
    final gray = const Color(0xFF6B7280);

    // 计算与各颜色的距离
    final redDist = _colorDistance(colorValue, red.value);
    final greenDist = _colorDistance(colorValue, green.value);
    final blueDist = _colorDistance(colorValue, blue.value);
    final grayDist = _colorDistance(colorValue, gray.value);

    // 找出最接近的颜色
    final minDist = [
      redDist,
      greenDist,
      blueDist,
      grayDist,
    ].reduce((a, b) => a < b ? a : b);

    if (minDist == redDist) return 'red';
    if (minDist == greenDist) return 'green';
    if (minDist == blueDist) return 'blue';
    return 'gray';
  }

  /// 计算颜色距离
  static int _colorDistance(int color1, int color2) {
    final r1 = (color1 >> 16) & 0xFF;
    final g1 = (color1 >> 8) & 0xFF;
    final b1 = color1 & 0xFF;

    final r2 = (color2 >> 16) & 0xFF;
    final g2 = (color2 >> 8) & 0xFF;
    final b2 = color2 & 0xFF;

    return ((r1 - r2) * (r1 - r2) +
            (g1 - g2) * (g1 - g2) +
            (b1 - b2) * (b1 - b2))
        .toInt();
  }

  /// 获取浅色模式背景色
  static Color _getLightBackground(Color color) {
    return color.withOpacity(0.08);
  }

  /// 获取深色模式背景色
  static Color _getDarkBackground(Color color) {
    return color.withOpacity(0.15);
  }

  /// 获取浅色模式文本颜色
  static Color _getLightTextColor(Color color) {
    return color.withOpacity(0.8);
  }

  /// 获取深色模式文本颜色
  static Color _getDarkTextColor(Color color) {
    return color.withOpacity(0.9);
  }

  /// 获取浅色模式次要文本颜色
  static Color _getLightSubtext(Color color) {
    return color.withOpacity(0.6);
  }

  /// 获取深色模式次要文本颜色
  static Color _getDarkSubtext(Color color) {
    return color.withOpacity(0.7);
  }
}
