/// 日视图活动小组件数据模型
///
/// 存储指定日期的活动数据，包括24小时时间轴、活动列表和统计信息
library;

/// 24小时时间轴数据项
class HourActivityItem {
  final int hour; // 0-23 小时
  final int totalMinutes; // 该小时总活动时长（分钟）
  final String? topTag; // 该小时主要活动标签（时长最长的标签）
  final int? color; // 主要活动标签的颜色值（ARGB格式）

  HourActivityItem({
    required this.hour,
    required this.totalMinutes,
    this.topTag,
    this.color,
  });

  /// 获取该小时的填充比例（用于UI显示）
  double get fillRatio {
    return (totalMinutes / 60).clamp(0.0, 1.0);
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minutes': totalMinutes,
      'tag': topTag,
      'color': color,
    };
  }

  /// 从JSON反序列化
  factory HourActivityItem.fromJson(Map<String, dynamic> json) {
    return HourActivityItem(
      hour: json['hour'] as int,
      totalMinutes: json['minutes'] as int,
      topTag: json['tag'] as String?,
      color: json['color'] as int?,
    );
  }
}

/// 日标签数据项
class DailyTagItem {
  final String tagName;
  final Duration totalDuration;
  final int activityCount;
  final int color; // 标签颜色值（ARGB格式）

  DailyTagItem({
    required this.tagName,
    required this.totalDuration,
    required this.activityCount,
    required this.color,
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
      'color': color,
    };
  }

  /// 从JSON反序列化
  factory DailyTagItem.fromJson(Map<String, dynamic> json) {
    return DailyTagItem(
      tagName: json['name'] as String,
      totalDuration: Duration(seconds: json['duration'] as int),
      activityCount: json['count'] as int,
      color: json['color'] as int? ?? 0xFF607afb,
    );
  }
}

/// 时间轴数据模型（供Android端使用）
class ActivityDailyTimeline {
  final List<double> amBars; // 上午0-11点活动条比例 (12个值)
  final List<int> pmDots; // 下午12-23点活动点颜色值 (12个值)

  ActivityDailyTimeline({
    required this.amBars,
    required this.pmDots,
  });

  Map<String, dynamic> toJson() {
    return {
      'amBars': amBars,
      'pmDots': pmDots,
    };
  }

  factory ActivityDailyTimeline.fromJson(Map<String, dynamic> json) {
    return ActivityDailyTimeline(
      amBars: (json['amBars'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      pmDots: (json['pmDots'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }
}

/// Android端活动列表项数据
class AndroidActivityItem {
  final String name;
  final String emoji;
  final String duration;
  final int color;
  final List<String> tags; // 活动标签列表

  AndroidActivityItem({
    required this.name,
    required this.emoji,
    required this.duration,
    required this.color,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emoji': emoji,
      'duration': duration,
      'color': color,
      'tags': tags,
    };
  }

  factory AndroidActivityItem.fromJson(Map<String, dynamic> json) {
    return AndroidActivityItem(
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📋',
      duration: json['duration'] as String,
      color: (json['color'] as num).toInt(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// 日视图小组件完整数据
class ActivityDailyWidgetData {
  final DateTime date; // 目标日期
  final List<HourActivityItem> hourlyActivities; // 24小时时间轴数据
  final List<DailyTagItem> topTags; // 按时长排序的标签列表（前20个）
  final List<AndroidActivityItem> activities; // Android端活动列表项
  final Duration totalDuration; // 当日总活动时长
  final int activityCount; // 当日活动总数

  ActivityDailyWidgetData({
    required this.date,
    required this.hourlyActivities,
    required this.topTags,
    required this.activities,
    required this.totalDuration,
    required this.activityCount,
  });

  /// 获取格式化日期文本（如: "5月28日"）
  String get dateText {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year && date.month == now.month && date.day == now.day - 1;
    final isTomorrow = date.year == now.year && date.month == now.month && date.day == now.day + 1;

    if (isToday) return '今天';
    if (isYesterday) return '昨天';
    if (isTomorrow) return '明天';

    return '${date.month}月${date.day}日';
  }

  /// 获取进度百分比（基于16小时工作日计算）
  double get progressPercentage {
    const targetMinutes = 16 * 60; // 16小时 = 960分钟
    final progress = (totalDuration.inMinutes / targetMinutes).clamp(0.0, 1.0);
    return progress * 100;
  }

  /// 构建时间轴数据（供Android端使用）
  ActivityDailyTimeline get timeline {
    // 上午0-11点的活动条比例
    final amBars = <double>[];
    for (var hour = 0; hour < 12; hour++) {
      final item = hourlyActivities.firstWhere(
        (e) => e.hour == hour,
        orElse: () => HourActivityItem(hour: hour, totalMinutes: 0),
      );
      amBars.add(item.fillRatio);
    }

    // 下午12-23点的活动点颜色值
    final pmDots = <int>[];
    for (var hour = 12; hour < 24; hour++) {
      final item = hourlyActivities.firstWhere(
        (e) => e.hour == hour,
        orElse: () => HourActivityItem(hour: hour, totalMinutes: 0, color: 0),
      );
      // 如果有活动且有颜色值，使用该颜色；否则使用0（无活动）
      pmDots.add(item.totalMinutes > 0 && item.color != null ? item.color! : 0);
    }

    return ActivityDailyTimeline(amBars: amBars, pmDots: pmDots);
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dateText': dateText, // Android端需要的格式化日期文本
      'progressPercent': progressPercentage.round(), // Android端需要的进度百分比
      'timeline': timeline.toJson(), // Android端需要的时间轴数据
      'hourlyActivities': hourlyActivities.map((e) => e.toJson()).toList(),
      'topTags': topTags.map((e) => e.toJson()).toList(),
      'activities': activities.map((e) => e.toJson()).toList(), // Android端需要
      'totalDuration': totalDuration.inSeconds,
      'activityCount': activityCount,
    };
  }

  /// 从JSON反序列化
  factory ActivityDailyWidgetData.fromJson(Map<String, dynamic> json) {
    return ActivityDailyWidgetData(
      date: DateTime.parse(json['date'] as String),
      hourlyActivities: (json['hourlyActivities'] as List<dynamic>)
          .map((e) => HourActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      topTags: (json['topTags'] as List<dynamic>)
          .map((e) => DailyTagItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      activities: (json['activities'] as List<dynamic>? ?? [])
          .map((e) => AndroidActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDuration: Duration(seconds: json['totalDuration'] as int),
      activityCount: json['activityCount'] as int,
    );
  }
}
