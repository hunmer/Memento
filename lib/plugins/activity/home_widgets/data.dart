/// 活动插件主页小组件数据模型
library;

/// 一天活动数据（用于7天统计）
class DayActivityData {
  final DateTime date;
  final int totalMinutes;
  final int activityCount;

  const DayActivityData({
    required this.date,
    required this.totalMinutes,
    required this.activityCount,
  });
}

/// 时间槽数据
class TimeSlotData {
  final int hour;
  final int minute;
  final int durationMinutes;

  /// 标签到时长的映射（用于确定主要标签颜色）
  final Map<String, int> tagDurations;

  TimeSlotData({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });

  /// 获取持续时间最长的标签
  String? get primaryTag {
    if (tagDurations.isEmpty) return null;
    return tagDurations.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// 时间槽数据包装类（用于公共组件数据传递）
class TimeSlotDataWrapper {
  final int hour;
  final int minute;
  final int durationMinutes;
  final Map<String, int> tagDurations;

  TimeSlotDataWrapper({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });
}
