import 'dart:math';

/// 热力图数据模型
///
/// 存储7天×24小时的活动密度数据
class ActivityHeatmapData {
  final List<List<int>> heatmap; // [day][hour] = 活动次数

  ActivityHeatmapData({required this.heatmap});

  /// 获取最大活动次数（用于归一化强度）
  int get maxCount {
    if (heatmap.isEmpty) return 0;
    return heatmap
        .expand((dayData) => dayData)
        .reduce((a, b) => max(a, b));
  }

  /// 获取指定日期和小时的活动次数
  int getCount(int day, int hour) {
    if (day < 0 || day >= heatmap.length) return 0;
    if (hour < 0 || hour >= 24) return 0;
    return heatmap[day][hour];
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'heatmap': heatmap,
      'maxCount': maxCount,
    };
  }

  /// 从JSON反序列化
  factory ActivityHeatmapData.fromJson(Map<String, dynamic> json) {
    final heatmapData = json['heatmap'] as List<dynamic>;
    final heatmap = heatmapData
        .map((dayData) => List<int>.from(dayData as List))
        .toList();

    return ActivityHeatmapData(heatmap: heatmap);
  }
}

/// 周标签数据模型
///
/// 存储单个活动标签在本周的统计信息
class WeeklyTagItem {
  final String tagName;
  final Duration totalDuration;
  final int activityCount;

  WeeklyTagItem({
    required this.tagName,
    required this.totalDuration,
    required this.activityCount,
  });

  /// 格式化时长显示（如: "2時30分"）
  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}時${minutes.toString().padLeft(2, '0')}分';
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': tagName,
      'duration': totalDuration.inSeconds,
      'count': activityCount,
    };
  }

  /// 从JSON反序列化
  factory WeeklyTagItem.fromJson(Map<String, dynamic> json) {
    return WeeklyTagItem(
      tagName: json['name'] as String,
      totalDuration: Duration(seconds: json['duration'] as int),
      activityCount: json['count'] as int,
    );
  }
}

/// 完整的周数据模型
///
/// 包含指定周的所有统计数据：基本信息、热力图、标签列表
class ActivityWeeklyData {
  final int year;
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final ActivityHeatmapData heatmap;
  final List<WeeklyTagItem> topTags; // 前20个标签

  ActivityWeeklyData({
    required this.year,
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.heatmap,
    required this.topTags,
  });

  /// 获取周范围显示文本（如: "第3周 1.15-1.21"）
  String get weekRangeText {
    final startMonth = weekStart.month;
    final startDay = weekStart.day;
    final endMonth = weekEnd.subtract(const Duration(days: 1)).month;
    final endDay = weekEnd.subtract(const Duration(days: 1)).day;

    return '第${weekNumber}周 $startMonth.$startDay-$endMonth.$endDay';
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'weekNumber': weekNumber,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'heatmap': heatmap.toJson(),
      'topTags': topTags.map((tag) => tag.toJson()).toList(),
    };
  }

  /// 从JSON反序列化
  factory ActivityWeeklyData.fromJson(Map<String, dynamic> json) {
    return ActivityWeeklyData(
      year: json['year'] as int,
      weekNumber: json['weekNumber'] as int,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      heatmap: ActivityHeatmapData.fromJson(json['heatmap'] as Map<String, dynamic>),
      topTags: (json['topTags'] as List<dynamic>)
          .map((tagJson) => WeeklyTagItem.fromJson(tagJson as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 创建空数据（用于首次配置）
  factory ActivityWeeklyData.empty({
    required int year,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    return ActivityWeeklyData(
      year: year,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      heatmap: ActivityHeatmapData(
        heatmap: List.generate(7, (_) => List.filled(24, 0)),
      ),
      topTags: [],
    );
  }
}
