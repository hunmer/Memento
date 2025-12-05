/// 习惯周视图小组件数据模型
class HabitsWeeklyData {
  final int year;
  final int week; // ISO 8601周数
  final String weekStart; // 格式化的周起始日期 (MM.DD)
  final String weekEnd; // 格式化的周结束日期 (MM.DD)
  final List<HabitWeeklyItem> habitItems;

  const HabitsWeeklyData({
    required this.year,
    required this.week,
    required this.weekStart,
    required this.weekEnd,
    required this.habitItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'week': week,
      'weekStart': weekStart,
      'weekEnd': weekEnd,
      'habitItems': habitItems.map((item) => item.toMap()).toList(),
    };
  }

  factory HabitsWeeklyData.fromMap(Map<String, dynamic> map) {
    return HabitsWeeklyData(
      year: map['year'] as int,
      week: map['week'] as int,
      weekStart: map['weekStart'] as String,
      weekEnd: map['weekEnd'] as String,
      habitItems: (map['habitItems'] as List)
          .map((item) => HabitWeeklyItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 单个习惯的周数据
class HabitWeeklyItem {
  final String habitId;
  final String habitTitle;
  final String habitIcon; // emoji或MaterialIcons codePoint字符串
  final List<int> dailyMinutes; // [周一,周二,...周日]共7个时长(分钟)
  final int colorValue; // 从技能或习惯ID哈希获取的颜色值

  const HabitWeeklyItem({
    required this.habitId,
    required this.habitTitle,
    required this.habitIcon,
    required this.dailyMinutes,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'habitTitle': habitTitle,
      'habitIcon': habitIcon,
      'dailyMinutes': dailyMinutes,
      'colorValue': colorValue,
    };
  }

  factory HabitWeeklyItem.fromMap(Map<String, dynamic> map) {
    return HabitWeeklyItem(
      habitId: map['habitId'] as String,
      habitTitle: map['habitTitle'] as String,
      habitIcon: map['habitIcon'] as String,
      dailyMinutes: List<int>.from(map['dailyMinutes'] as List),
      colorValue: map['colorValue'] as int,
    );
  }
}
