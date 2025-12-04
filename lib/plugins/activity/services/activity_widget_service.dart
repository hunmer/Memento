import 'dart:math';
import '../activity_plugin.dart';
import '../models/activity_record.dart';
import '../models/activity_weekly_widget_data.dart';
import '../models/activity_daily_widget_data.dart';

/// 周视图小组件业务逻辑服务
///
/// 负责计算周数据、生成热力图、统计标签时长
class ActivityWidgetService {
  final ActivityPlugin plugin;

  /// 默认颜色列表，用于没有设置颜色的活动
  static const List<int> _defaultColors = [
    0xFF607afb, // 蓝色
    0xFF4CAF50, // 绿色
    0xFFFF9800, // 橙色
    0xFFE91E63, // 粉色
    0xFF9C27B0, // 紫色
    0xFF00BCD4, // 青色
    0xFFFF5722, // 深橙色
    0xFF795548, // 棕色
    0xFF009688, // 青绿色
    0xFF3F51B5, // 靛蓝色
  ];

  ActivityWidgetService(this.plugin);

  /// 计算指定周的数据
  ///
  /// [weekOffset]: 周偏移量，0=本周，-1=上周，1=下周
  ///
  /// 返回包含热力图、标签统计、周范围信息的完整数据
  Future<ActivityWeeklyData> calculateWeekData(int weekOffset) async {
    // 1. 计算周起止日期（ISO 8601：周一为第一天）
    final now = DateTime.now();
    final targetWeek = now.add(Duration(days: weekOffset * 7));
    final weekStart = _getWeekStart(targetWeek);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // 2. 获取该周所有活动
    final activities = <ActivityRecord>[];
    for (
      var date = weekStart;
      date.isBefore(weekEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final dailyActivities = await plugin.activityService.getActivitiesForDate(
        date,
      );
      activities.addAll(dailyActivities);
    }

    // 3. 统计标签时长并排序（前20）- 需要先计算，用于获取标签颜色映射
    final tagStats = _calculateTagStats(activities);
    final sortedTagEntries =
        tagStats.entries.toList()
          ..sort((a, b) => b.value.duration.compareTo(a.value.duration));

    // 为每个标签分配颜色
    final topTags = <WeeklyTagItem>[];
    for (var i = 0; i < sortedTagEntries.length; i++) {
      final entry = sortedTagEntries[i];
      topTags.add(
        WeeklyTagItem(
          tagName: entry.key,
          totalDuration: entry.value.duration,
          activityCount: entry.value.count,
          color: _defaultColors[i % _defaultColors.length],
        ),
      );
    }

    // 4. 生成热力图数据（使用活动颜色）
    final tagColorMap = _buildTagColorMap(topTags);
    final heatmap = _buildHeatmap(activities, weekStart, tagColorMap);

    // 5. 计算周数（ISO 8601）
    final weekNumber = _calculateWeekOfYear(targetWeek);

    return ActivityWeeklyData(
      year: targetWeek.year,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      heatmap: ActivityHeatmapData(heatmap: heatmap),
      topTags: topTags.take(20).toList(),
    );
  }

  /// 构建标签到颜色的映射
  ///
  /// 直接使用 WeeklyTagItem 中已分配的颜色
  Map<String, int> _buildTagColorMap(List<WeeklyTagItem> sortedTags) {
    final colorMap = <String, int>{};
    for (var tag in sortedTags) {
      colorMap[tag.tagName] = tag.color;
    }
    return colorMap;
  }

  /// 生成热力图（24小时×7天）
  ///
  /// [activities]: 活动记录列表
  /// [weekStart]: 周起始日期（周一）
  /// [tagColorMap]: 标签到颜色的映射
  ///
  /// 返回二维数组：heatmap[hour][day] = 活动颜色值（0表示无活动）
  /// 注意：Android端布局是24行×7列，索引计算为 index = hour * 7 + day
  List<List<int>> _buildHeatmap(
    List<ActivityRecord> activities,
    DateTime weekStart,
    Map<String, int> tagColorMap,
  ) {
    // 初始化24小时×7天的二维数组（0 = 无活动）
    final heatmap = List.generate(24, (_) => List.filled(7, 0));
    return heatmap;
  }


  /// 统计标签时长
  ///
  /// [activities]: 活动记录列表
  ///
  /// 返回Map：tagName -> (总时长, 活动次数)
  Map<String, ({Duration duration, int count})> _calculateTagStats(
    List<ActivityRecord> activities,
  ) {
    final stats = <String, ({Duration duration, int count})>{};

    for (var activity in activities) {
      final duration = activity.endTime.difference(activity.startTime);

      // 为每个标签累加时长和次数
      for (var tag in activity.tags) {
        final existing = stats[tag];
        stats[tag] = (
          duration: (existing?.duration ?? Duration.zero) + duration,
          count: (existing?.count ?? 0) + 1,
        );
      }
    }

    return stats;
  }

  /// 获取周起始日期（周一 00:00:00）
  ///
  /// ISO 8601标准：一周从周一开始
  /// 返回的日期时间归一化到 00:00:00，确保日期计算准确
  DateTime _getWeekStart(DateTime date) {
    // weekday: 1=周一, 7=周日
    final monday = date.subtract(Duration(days: date.weekday - 1));
    // 归一化到 00:00:00
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// 计算ISO 8601周数
  ///
  /// ISO 8601规则：
  /// - 一年的第1周包含该年的第一个星期四
  /// - 等价于：第1周包含1月4日
  /// - 周数从1开始计数
  ///
  /// 返回值范围：1-53
  int _calculateWeekOfYear(DateTime date) {
    // 找到该年1月4日（必然在第1周内）
    final firstDayOfYear = DateTime(date.year, 1, 4);

    // 找到1月4日所在周的周一
    final firstMonday = firstDayOfYear.subtract(
      Duration(days: (firstDayOfYear.weekday - 1) % 7),
    );

    // 计算目标日期距第1周周一的天数
    final daysSinceFirstMonday = date.difference(firstMonday).inDays;

    // 周数 = 天数 / 7 + 1
    return max(1, (daysSinceFirstMonday / 7).floor() + 1);
  }

  /// 获取指定年度的周数范围
  ///
  /// 用于限制周切换范围（仅本年度）
  ///
  /// 返回(最小周数, 最大周数)
  ({int minWeek, int maxWeek}) getWeekRangeForYear(int year) {
    // 计算该年最后一天所在的周数
    final lastDayOfYear = DateTime(year, 12, 31);
    final maxWeek = _calculateWeekOfYear(lastDayOfYear);

    return (minWeek: 1, maxWeek: maxWeek);
  }

  /// 根据周偏移量计算目标周的基本信息
  ///
  /// [weekOffset]: 周偏移量
  ///
  /// 返回(年份, 周数, 周起始日期, 周结束日期)
  ({int year, int weekNumber, DateTime weekStart, DateTime weekEnd})
  getWeekInfo(int weekOffset) {
    final now = DateTime.now();
    final targetWeek = now.add(Duration(days: weekOffset * 7));
    final weekStart = _getWeekStart(targetWeek);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekNumber = _calculateWeekOfYear(targetWeek);

    return (
      year: targetWeek.year,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }

  /// 计算指定日期的数据
  ///
  /// [dayOffset]: 日期偏移量，0=今天，-1=昨天，1=明天
  ///
  /// 返回包含24小时时间轴、活动列表和统计信息的完整数据
  Future<ActivityDailyWidgetData> calculateDayData(int dayOffset) async {
    // 1. 计算目标日期
    final now = DateTime.now();
    final targetDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: dayOffset));

    // 2. 获取该日所有活动
    final activities = await plugin.activityService.getActivitiesForDate(
      targetDate,
    );

    // 3. 统计标签时长并排序（前20）
    final tagStats = _calculateTagStats(activities);
    final sortedTagEntries =
        tagStats.entries.toList()
          ..sort((a, b) => b.value.duration.compareTo(a.value.duration));

    // 为每个标签分配颜色，并构建颜色映射
    final topTags = <DailyTagItem>[];
    final tagColorMap = <String, int>{};
    for (var i = 0; i < sortedTagEntries.length; i++) {
      final entry = sortedTagEntries[i];
      final color = _defaultColors[i % _defaultColors.length];
      tagColorMap[entry.key] = color;
      topTags.add(
        DailyTagItem(
          tagName: entry.key,
          totalDuration: entry.value.duration,
          activityCount: entry.value.count,
          color: color,
        ),
      );
    }

    // 4. 构建24小时时间轴数据（使用颜色映射）
    final hourlyActivities = _buildHourlyActivities(activities, tagColorMap);

    // 5. 构建Android端活动列表项
    final androidActivities = _buildAndroidActivities(activities, tagColorMap);

    // 6. 计算总时长和活动数
    final totalDuration = Duration(
      seconds: activities.fold<int>(
        0,
        (sum, activity) => sum + activity.endTime.difference(activity.startTime).inSeconds,
      ),
    );

    return ActivityDailyWidgetData(
      date: targetDate,
      hourlyActivities: hourlyActivities,
      topTags: topTags.take(20).toList(),
      activities: androidActivities,
      totalDuration: totalDuration,
      activityCount: activities.length,
    );
  }

  /// 构建24小时时间轴数据
  ///
  /// [activities]: 活动记录列表
  /// [tagColorMap]: 标签到颜色的映射
  ///
  /// 返回24个HourActivityItem，每个代表一小时的统计数据
  List<HourActivityItem> _buildHourlyActivities(
    List<ActivityRecord> activities,
    Map<String, int> tagColorMap,
  ) {
    final hourlyData = <int, ({Duration duration, Map<String, Duration> tagDurations})>{};

    // 初始化24小时数据
    for (var hour = 0; hour < 24; hour++) {
      hourlyData[hour] = (duration: Duration.zero, tagDurations: {});
    }

    // 累加每小时的时长和标签数据
    for (final activity in activities) {
      final startHour = activity.startTime.hour;
      final endHour = activity.endTime.hour;
      final activityDuration = activity.endTime.difference(activity.startTime);

      for (var hour = startHour; hour <= endHour; hour++) {
        if (hour < 0 || hour >= 24) continue;

        final currentData = hourlyData[hour]!;
        final newDuration = currentData.duration + activityDuration;

        // 为每个标签累加时长
        final newTagDurations = Map<String, Duration>.from(currentData.tagDurations);
        for (final tag in activity.tags) {
          newTagDurations[tag] = (newTagDurations[tag] ?? Duration.zero) + activityDuration;
        }

        hourlyData[hour] = (duration: newDuration, tagDurations: newTagDurations);
      }
    }

    // 转换为HourActivityItem列表
    return List.generate(24, (hour) {
      final data = hourlyData[hour]!;
      final totalMinutes = data.duration.inMinutes;

      // 找到时长最长的标签
      String? topTag;
      int? topTagColor;
      if (data.tagDurations.isNotEmpty) {
        final sortedEntries = data.tagDurations.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topTag = sortedEntries.first.key;

        // 使用标签颜色映射
        topTagColor = tagColorMap[topTag] ?? _defaultColors[0];
      }

      return HourActivityItem(
        hour: hour,
        totalMinutes: totalMinutes,
        topTag: topTag,
        color: topTagColor,
      );
    });
  }

  /// 构建Android端活动列表项
  ///
  /// [activities]: 活动记录列表
  /// [tagColorMap]: 标签到颜色的映射
  ///
  /// 返回用于Android RemoteViews的列表项数据
  List<AndroidActivityItem> _buildAndroidActivities(
    List<ActivityRecord> activities,
    Map<String, int> tagColorMap,
  ) {
    final items = <AndroidActivityItem>[];

    // 按开始时间排序
    final sortedActivities = [...activities]..sort(
      (a, b) => a.startTime.compareTo(b.startTime),
    );

    for (final activity in sortedActivities) {
      // 获取主要标签（第一个标签或最长的标签）
      String? primaryTag;
      if (activity.tags.isNotEmpty) {
        primaryTag = activity.tags.first;
      }

      // 获取颜色（优先使用活动颜色，其次使用标签颜色）
      int color;
      if (activity.color != null) {
        color = activity.color!.value;
      } else if (primaryTag != null && tagColorMap.containsKey(primaryTag)) {
        color = tagColorMap[primaryTag]!;
      } else {
        color = _defaultColors[0];
      }

      items.add(
        AndroidActivityItem(
          name: activity.title,
          emoji: activity.mood ?? '📋',
          duration: activity.formattedDuration,
          color: color,
          tags: activity.tags,
        ),
      );
    }

    return items;
  }
}
