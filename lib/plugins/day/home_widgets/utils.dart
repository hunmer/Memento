/// 纪念日插件主页小组件工具函数
library;

import '../models/memorial_day.dart';
import 'data.dart';

/// 根据天数范围过滤纪念日
///
/// [days] 纪念日列表
/// [startDay] 起始天数（负数=过去，0=今天，正数=未来）
/// [endDay] 结束天数（负数=过去，0=今天，正数=未来）
List<MemorialDay> filterMemorialDaysByDaysRange(
  List<MemorialDay> days,
  int? startDay,
  int? endDay,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return days.where((day) {
      final targetDate = DateTime(
        day.targetDate.year,
        day.targetDate.month,
        day.targetDate.day,
      );
      final daysDiff = targetDate.difference(today).inDays;

      // 如果 startDay 和 endDay 都为 null，显示全部
      if (startDay == null && endDay == null) {
        return true;
      }

      // 检查天数差是否在范围内
      final inRange =
          (startDay == null || daysDiff >= startDay) &&
          (endDay == null || daysDiff <= endDay);

      return inRange;
    }).toList()
    ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
}

/// 获取星期几名称
String getWeekday(int weekday) {
  const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return weekdays[weekday - 1];
}

/// 获取月份名称
String getMonth(int month) {
  const months = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];
  return months[month - 1];
}

/// 获取本周日期列表
List<int> getWeekDates() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return List.generate(7, (index) => monday.add(Duration(days: index)).day);
}

/// 将纪念日转换为列表项数据
MemorialDayListItemData memorialDayToListItemData(MemorialDay day) {
  String statusText;
  if (day.isToday) {
    statusText = '就是今天！';
  } else if (day.isExpired) {
    statusText = '已过 ${day.daysPassed} 天';
  } else {
    statusText = '剩余 ${day.daysRemaining} 天';
  }

  return MemorialDayListItemData(
    id: day.id,
    title: day.title,
    date: '${day.targetDate.month}/${day.targetDate.day}',
    statusText: statusText,
    statusColor: day.isExpired
        ? 'grey'
        : (day.isToday
            ? 'red'
            : (day.daysRemaining <= 7 ? 'orange' : 'primary')),
    backgroundColor: day.backgroundColor.value,
    daysRemaining: day.daysRemaining,
    daysPassed: day.daysPassed,
    isToday: day.isToday,
    isExpired: day.isExpired,
  );
}

/// 格式化纪念日日期为中文格式
String formatDateLocalized(DateTime date) {
  return '${date.month}月${date.day}日';
}

/// 获取纪念日状态文本
String getMemorialDayStatusText(MemorialDay day) {
  if (day.isToday) {
    return '就是今天！';
  } else if (day.isExpired) {
    return '已过 ${day.daysPassed} 天';
  } else {
    return '剩余 ${day.daysRemaining} 天';
  }
}

/// 计算纪念日进度百分比（基于365天）
double calculateMemorialDayProgress(MemorialDay day) {
  final effectiveDays = day.isExpired ? day.daysPassed : day.daysRemaining;
  final progress = ((365 - effectiveDays) / 365).clamp(0.0, 1.0);
  return progress;
}

/// 计算纪念日进度百分比（用于显示）
int calculateMemorialDayPercentage(MemorialDay day) {
  final effectiveDays = day.isExpired ? day.daysPassed : day.daysRemaining;
  final percentage = ((365 - effectiveDays) / 365 * 100).clamp(0, 100);
  return percentage.toInt();
}
