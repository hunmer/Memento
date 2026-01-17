/// 活动插件主页小组件工具函数

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import '../models/activity_record.dart';

/// 根据平均活动时长获取状态描述
String getActivityStatus(double avgMinutes) {
  if (avgMinutes >= 720) return '非常活跃'; // 12小时以上
  if (avgMinutes >= 480) return '很活跃'; // 8小时以上
  if (avgMinutes >= 360) return '活跃'; // 6小时以上
  if (avgMinutes >= 240) return '适度活动'; // 4小时以上
  if (avgMinutes >= 120) return '轻度活动'; // 2小时以上
  if (avgMinutes >= 60) return '少量活动'; // 1小时以上
  return '需要更多活动';
}

/// 格式化时间范围（静态版本）
String formatTimeRangeStatic(DateTime start, DateTime end) {
  return '${formatTimeStatic(start)} - ${formatTimeStatic(end)}';
}

/// 格式化时间（HH:mm）（静态版本）
String formatTimeStatic(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

/// 从标签生成颜色（与 ActivityGridView 保持一致）
Color getColorFromTag(String tag) {
  final baseHue = (tag.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
}

/// 格式化时长为显示文本（如果超过60分钟转小时，带小数点）
String formatDurationForDisplay(int minutes) {
  if (minutes >= 60) {
    final hours = minutes / 60;
    // 如果是整数小时，不显示小数
    if (hours == hours.truncateToDouble()) {
      return '${hours.toInt()}小时';
    }
    // 否则显示一位小数
    return '${hours.toStringAsFixed(1)}小时';
  }
  return '$minutes分钟';
}

/// 格式化活动列表的时间段为字符串
String formatActivitiesTimeRange(List<ActivityRecord> activities) {
  if (activities.isEmpty) return '';

  // 按开始时间排序
  final sortedActivities = List<ActivityRecord>.from(activities);
  sortedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));

  // 最多显示3个时间段
  final timeRanges = sortedActivities
      .take(3)
      .map((a) => formatTimeRangeStatic(a.startTime, a.endTime))
      .toList();

  if (sortedActivities.length > 3) {
    return '${timeRanges.join('、')}...';
  }

  return timeRanges.join('、');
}

/// 将活动记录转换为 DailyScheduleCardWidget 的 EventData 格式
Map<String, dynamic> convertActivityToEventData(ActivityRecord activity) {
  // 将 24 小时制转换为 12 小时制
  final startHour = activity.startTime.hour;
  final endHour = activity.endTime.hour;

  final startPeriod = startHour >= 12 ? 'PM' : 'AM';
  final endPeriod = endHour >= 12 ? 'PM' : 'AM';

  final startHour12 = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
  final endHour12 = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);

  // 根据标签选择颜色
  String color = 'gray';
  if (activity.tags.isNotEmpty) {
    final primaryTag = activity.tags.first;
    color = getColorNameFromTag(primaryTag);
  }

  return {
    'title': activity.title.isEmpty ? '未命名活动' : activity.title,
    'startTime': startHour12.toString().padLeft(2, '0'),
    'startPeriod': startPeriod,
    'endTime': endHour12.toString().padLeft(2, '0'),
    'endPeriod': endPeriod,
    'color': color,
    'location': null,
    'isAllDay': false,
  };
}

/// 根据标签获取颜色名称
String getColorNameFromTag(String tag) {
  final colorValue = getColorFromTag(tag).value;

  // 简单映射：根据颜色值范围选择预设颜色
  if (colorValue == 0xFFF97316) return 'orange';
  if (colorValue == 0xFF4ADE80) return 'green';
  if (colorValue == 0xFF60A5FA) return 'blue';
  if (colorValue == 0xFFF87171) return 'red';
  return 'gray';
}

/// 构建时间线日程卡片数据
/// 显示今天和昨天的活动（ TimelineScheduleCard 组件使用）
Map<String, dynamic> buildTimelineScheduleCardData(
  List<ActivityRecord> todayActivities,
  List<ActivityRecord> yesterdayActivities,
  DateTime now,
) {
  // 计算昨天的日期
  final yesterday = now.subtract(const Duration(days: 1));

  // 获取星期名称
  final todayWeekday = getWeekdayName(now.weekday);
  final yesterdayWeekday = getWeekdayName(yesterday.weekday);

  // 转换今日活动为 TimelineEvent 格式
  final todayEvents = todayActivities
      .map((a) => convertActivityToTimelineEvent(a))
      .toList();

  // 转换昨日活动为 TimelineEvent 格式
  final yesterdayEvents = yesterdayActivities
      .map((a) => convertActivityToTimelineEvent(a))
      .toList();

  return {
    'todayWeekday': todayWeekday,
    'todayDay': now.day,
    'tomorrowWeekday': yesterdayWeekday,
    'tomorrowDay': yesterday.day,
    'todayEvents': todayEvents,
    'tomorrowEvents': yesterdayEvents,
  };
}

/// 获取星期名称（中文）
String getWeekdayName(int weekday) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return weekdays[(weekday - 1) % 7];
}

/// 将活动记录转换为 TimelineEvent 格式
Map<String, dynamic> convertActivityToTimelineEvent(
  ActivityRecord activity,
) {
  // 获取主标签颜色
  final tagColor = activity.tags.isNotEmpty
      ? getColorFromTag(activity.tags.first)
      : Colors.pink;

  // 计算背景色和文本色
  final backgroundColorLight = tagColor.withOpacity(0.15);
  final backgroundColorDark = tagColor.withOpacity(0.25);
  final textColorLight = tagColor;
  final textColorDark = tagColor.withOpacity(0.9);

  // 格式化时间显示（如 "9:45AM"）
  final timeDisplay = formatTimeToAMPM(activity.startTime);

  return {
    'hour': activity.startTime.hour,
    'title': activity.title.isEmpty ? '未命名活动' : activity.title,
    'time': timeDisplay,
    'color': tagColor.value,
    'backgroundColorLight': backgroundColorLight.value,
    'backgroundColorDark': backgroundColorDark.value,
    'textColorLight': textColorLight.value,
    'textColorDark': textColorDark.value,
    'subtextLight': const Color(0xFF8E8E93).value,
    'subtextDark': const Color(0xFF98989D).value,
  };
}

/// 格式化时间为 AM/PM 格式（如 "9:45AM"）
String formatTimeToAMPM(DateTime time) {
  final hour = time.hour;
  final minute = time.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr$period';
}

/// 从选择器数据提取热力图配置
Map<String, dynamic> extractHeatmapConfig(List<dynamic> dataArray) {
  int granularity = 60; // 默认值
  final item = dataArray[0];

  // 提取 rawData
  if (item is SelectableItem) {
    granularity = item.rawData as int;
  } else if (item is int) {
    granularity = item;
  }

  return {'timeGranularity': granularity};
}
