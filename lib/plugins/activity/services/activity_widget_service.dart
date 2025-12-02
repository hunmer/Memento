import 'dart:math';
import '../activity_plugin.dart';
import '../models/activity_record.dart';
import '../models/activity_weekly_widget_data.dart';

/// 周视图小组件业务逻辑服务
///
/// 负责计算周数据、生成热力图、统计标签时长
class ActivityWidgetService {
  final ActivityPlugin plugin;

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
    for (var date = weekStart;
        date.isBefore(weekEnd);
        date = date.add(const Duration(days: 1))) {
      final dailyActivities =
          await plugin.activityService.getActivitiesForDate(date);
      activities.addAll(dailyActivities);
    }

    // 3. 生成热力图数据（统计每小时活动次数）
    final heatmap = _buildHeatmap(activities, weekStart);

    // 4. 统计标签时长并排序（前20）
    final tagStats = _calculateTagStats(activities);
    final topTags = tagStats.entries
        .map((e) => WeeklyTagItem(
              tagName: e.key,
              totalDuration: e.value.duration,
              activityCount: e.value.count,
            ))
        .toList()
      ..sort((a, b) => b.totalDuration.compareTo(a.totalDuration));

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

  /// 生成热力图（7天×24小时）
  ///
  /// [activities]: 活动记录列表
  /// [weekStart]: 周起始日期（周一）
  ///
  /// 返回二维数组：heatmap[day][hour] = 活动次数
  List<List<int>> _buildHeatmap(
      List<ActivityRecord> activities, DateTime weekStart) {
    // 初始化7天×24小时的二维数组
    final heatmap = List.generate(7, (_) => List.filled(24, 0));

    for (var activity in activities) {
      // 计算活动所属的星期几（0=周一，6=周日）
      final dayIndex = activity.startTime.difference(weekStart).inDays;

      // 只统计本周内的活动
      if (dayIndex >= 0 && dayIndex < 7) {
        final hourIndex = activity.startTime.hour;

        // 活动可能跨越多个小时，统计每个小时
        final startHour = activity.startTime.hour;
        final endHour = activity.endTime.hour;
        final isSameDay = activity.startTime.day == activity.endTime.day;

        if (isSameDay) {
          // 同一天内，统计跨越的每个小时
          for (var hour = startHour;
              hour <= endHour && hour < 24;
              hour++) {
            heatmap[dayIndex][hour]++;
          }
        } else {
          // 跨天活动，只统计起始小时
          heatmap[dayIndex][startHour]++;
        }
      }
    }

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

  /// 获取周起始日期（周一）
  ///
  /// ISO 8601标准：一周从周一开始
  DateTime _getWeekStart(DateTime date) {
    // weekday: 1=周一, 7=周日
    return date.subtract(Duration(days: date.weekday - 1));
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
      weekEnd: weekEnd
    );
  }
}
