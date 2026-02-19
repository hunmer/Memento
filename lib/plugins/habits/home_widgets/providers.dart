/// 习惯追踪插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/utils/color_extensions.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final dynamic plugin = PluginManager.instance.getPlugin('habits');
    if (plugin == null) return [];

    // 使用动态类型避免循环导入
    final habitController = plugin.getHabitController();
    final skillController = plugin.getSkillController();
    final timerController = plugin.timerController;

    final habitCount = habitController.getHabits().length;
    final skillCount = skillController.getSkills().length;
    final activeTimers = timerController.getActiveTimers();
    final activeTimerCount = activeTimers.values.where((v) => v).length;

    return [
      StatItemData(
        id: 'habits_count',
        label: '习惯数',
        value: '$habitCount',
        highlight: habitCount > 0,
        color: Colors.amber,
      ),
      StatItemData(
        id: 'skills_count',
        label: '技能数',
        value: '$skillCount',
        highlight: false,
      ),
      StatItemData(
        id: 'active_timers_count',
        label: '活动计时器',
        value: '$activeTimerCount',
        highlight: activeTimerCount > 0,
        color: Colors.orange,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 从选择器数据中提取小组件需要的数据
Map<String, dynamic> extractHabitHeatmapData(List<dynamic> dataArray) {
  if (dataArray.isEmpty) {
    return {};
  }

  final rawData = dataArray[0];

  // 处理 Habit 对象
  if (rawData is Habit) {
    return {
      'id': rawData.id,
      'title': rawData.title,
      'group': rawData.group,
      'icon': rawData.icon,
      'color': HabitsUtils.generateColorForHabit(rawData).value,
    };
  }

  // 处理 Map 类型
  if (rawData is Map<String, dynamic>) {
    final title = rawData['title']?.toString() ?? '';
    final id = rawData['id']?.toString() ?? '';
    final color = ColorGenerator.fromString(title.isNotEmpty ? title : id);
    return {
      'id': id,
      'title': title,
      'group': rawData['group']?.toString(),
      'icon': rawData['icon']?.toString(),
      'color': color.value,
    };
  }

  // 其他情况返回空 Map
  return {};
}

// ============================================================
// 活动统计公共小组件数据提供者
// 配置: dateRange (today/week/month/year), maxCount (5-10)
// ============================================================

/// 根据日期范围字符串获取日期范围
DateTimeRange _getDateRangeFromString(String dateRange) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (dateRange) {
    case 'today':
      return DateTimeRange(start: today, end: now);
    case 'week':
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(start: weekStart, end: now);
    case 'month':
      final monthStart = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: monthStart, end: now);
    case 'year':
      final yearStart = DateTime(now.year, 1, 1);
      return DateTimeRange(start: yearStart, end: now);
    default:
      return DateTimeRange(start: today, end: now);
  }
}

/// 获取习惯在指定日期范围内的统计数据
Future<_HabitStatsResult> _getHabitStatsInRange(
  String habitId,
  DateTimeRange range,
  dynamic recordController,
) async {
  final records =
      (await recordController.getHabitCompletionRecords(habitId) as List)
          .cast<CompletionRecord>();
  final filteredRecords =
      records.where((r) {
        return r.date.isAfter(range.start) &&
            r.date.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

  final totalMinutes = filteredRecords.fold<int>(
    0,
    (sum, r) => sum + r.duration.inMinutes,
  );
  final completionCount = filteredRecords.length;

  return _HabitStatsResult(
    habitId: habitId,
    totalMinutes: totalMinutes,
    completionCount: completionCount,
  );
}

class _HabitStatsResult {
  final String habitId;
  final int totalMinutes;
  final int completionCount;

  _HabitStatsResult({
    required this.habitId,
    required this.totalMinutes,
    required this.completionCount,
  });
}

/// 活动统计公共小组件数据提供者
Future<Map<String, Map<String, dynamic>>> provideActivityStatsWidgets(
  Map<String, dynamic> config,
) async {
  final dynamic plugin = PluginManager.instance.getPlugin('habits');
  if (plugin == null) return {};

  // 使用动态类型避免循环导入
  final habitController = plugin.getHabitController();
  final recordController = plugin.getRecordController();

  final dateRangeStr = config['dateRange'] as String? ?? 'week';
  final maxCount = (config['maxCount'] as int?)?.clamp(1, 10) ?? 5;

  final dateRange = _getDateRangeFromString(dateRangeStr);
  final habits = (habitController.getHabits() as List).cast<Habit>();

  // 获取所有习惯的统计数据
  final statsFutures = habits.map(
    (h) => _getHabitStatsInRange(h.id, dateRange, recordController),
  );
  final statsResults = await Future.wait(statsFutures);

  // 按总时长排序
  final sortedStats = List<_HabitStatsResult>.from(statsResults)
    ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

  // 取前 maxCount 个
  final topStats = sortedStats.take(maxCount).toList();

  // 生成日期范围标签
  String dateRangeLabel;
  switch (dateRangeStr) {
    case 'today':
      dateRangeLabel = '今日';
    case 'week':
      dateRangeLabel = '本周';
    case 'month':
      dateRangeLabel = '本月';
    case 'year':
      dateRangeLabel = '本年';
    default:
      dateRangeLabel = '本周';
  }

  // 总计数据
  final totalMinutes = statsResults.fold<int>(
    0,
    (sum, s) => sum + s.totalMinutes,
  );
  final totalCompletions = statsResults.fold<int>(
    0,
    (sum, s) => sum + s.completionCount,
  );

  // topStats 的总时长（用于 rankedBarChartCard 的比例计算）
  final topTotalMinutes = topStats.fold<int>(
    0,
    (sum, s) => sum + s.totalMinutes,
  );

  // 为小组件准备数据
  final trackersData = <Map<String, dynamic>>[];
  final metricsData = <Map<String, dynamic>>[];
  final categoryData = <Map<String, dynamic>>[];
  final rankedData = <Map<String, dynamic>>[];

  for (final stat in topStats) {
    final habit = habits.firstWhere((h) => h.id == stat.habitId);
    final skillId = habit.skillId;
    String? skillName;
    final habitColor = HabitsUtils.generateColorForHabit(habit);

    if (skillId != null) {
      try {
        final skill = plugin.getSkillController().getSkillById(skillId);
        skillName = skill?.title;
      } catch (_) {}
    }

    final progress =
        habit.durationMinutes > 0
            ? (stat.totalMinutes / habit.durationMinutes * 100).clamp(0, 100)
            : 0.0;

    // MultiMetricProgressCard 数据
    trackersData.add({
      'emoji': habit.icon ?? '58353', // 使用 MaterialIcons codePoint，默认为 star
      'progress': progress,
      'progressColor': habitColor.value,
      'title': habit.title,
      'subtitle': skillName ?? habit.group ?? '习惯',
      'value': stat.totalMinutes.toDouble(),
      'unit': '分钟',
    });

    // CircularMetricsCard 数据
    metricsData.add({
      'icon':
          habit.icon != null
              ? int.parse(habit.icon!)
              : Icons.auto_awesome.codePoint,
      'value': '${stat.completionCount}次',
      'label': habit.title,
      'progress': (stat.totalMinutes / 60 / 10).clamp(0, 1), // 假设10小时为100%
      'color': habitColor.value,
    });

    // CategoryStackWidget 数据
    categoryData.add({
      'label': habit.title,
      'amount': stat.totalMinutes.toDouble(),
      'color': habitColor.value,
      'percentage':
          totalMinutes > 0 ? (stat.totalMinutes / totalMinutes * 100) : 0.0,
    });

    // RankedBarChartCard 数据
    // value 在循环结束后设置（第一个为 100%，其他的相对第一个）
    rankedData.add({
      'label': habit.title,
      'value': 0.0, // 稍后设置
      'color': habitColor.value,
    });
  }

  // 为 RankedBarChartCard 的每个项目设置 value 和颜色
  if (rankedData.isNotEmpty) {
    final rankColors = [
      0xFFFF6B6B, // 红色
      0xFF4ECDC4, // 青色
      0xFFFFD93D, // 黄色
      0xFF6BCB77, // 绿色
      0xFF4D96FF, // 蓝色
      0xFF9B59B6, // 紫色
      0xFFFF8C42, // 橙色
      0xFF00CED1, // 深青
      0xFFDC143C, // 深红
      0xFF2E8B57, // 海绿
    ];

    // 获取第一个习惯的时长作为基准（100%）
    final baseMinutes = topStats.first.totalMinutes;

    for (var i = 0; i < rankedData.length; i++) {
      // 第一个为 100%，其他的相对于第一个
      final ratio =
          baseMinutes > 0
              ? (topStats[i].totalMinutes / baseMinutes).clamp(0.0, 1.0)
              : 0.0;
      rankedData[i]['value'] = ratio;
      rankedData[i]['color'] = rankColors[i % rankColors.length];
    }
  }

  return {
    // MultiMetricProgressCard - 多指标进度卡片
    'multiMetricProgressCard': {'trackers': trackersData},

    // CircularMetricsCard - 环形指标卡片
    'circularMetricsCard': {
      'title': '$dateRangeLabel习惯统计',
      'metrics': metricsData,
    },

    // NutritionProgressCard (复用为习惯进度)
    'nutritionProgressCard': {
      'leftData': {
        'current': totalMinutes.toDouble(),
        'total': (maxCount * 60).toDouble(),
        'unit': '分钟',
      },
      'leftConfig': {
        'icon': '⏱️',
        'label': '$dateRangeLabel总时长',
        'subtext': '已完成$totalCompletions次',
      },
      'rightItems':
          trackersData.map((t) {
            return {
              'icon': t['emoji'],
              'name': t['title'],
              'current': t['value'],
              'total': (maxCount * 60).toDouble(),
              'color': t['progressColor'],
              'subtitle': t['unit'],
            };
          }).toList(),
    },

    // expenseDonutChart
    'expenseDonutChart': {
      'badgeLabel': '习惯',
      'timePeriod': dateRangeLabel,
      'totalAmount': totalMinutes.toDouble() / 60,
      'totalUnit': '小时',
      'categories': [
        for (var item in categoryData.take(5))
          {
            'label': item['label'],
            'percentage': item['percentage'],
            'color': item['color'],
            'subtitle': '${(item['amount'] / 60).toStringAsFixed(1)}小时',
          },
      ],
    },

    // PerformanceBarChart
    'performanceBarChart': {
      'badgeLabel': '习惯',
      'growthPercentage':
          topStats.isNotEmpty ? topStats.first.totalMinutes / 60 : 0.0,
      'timePeriod': dateRangeLabel,
      'barData':
          rankedData.take(5).map((item) {
            // value 需要转换为 0-100 之间的百分比
            return {
              'value': (item['value'] as double) * 100,
              'label': item['label'],
            };
          }).toList(),
      'footerLabel': '总时长',
    },

    // CategoryStackWidget
    'categoryStackWidget': {
      'title': '习惯分类',
      'currentAmount': totalMinutes.toDouble(),
      'targetAmount': (maxCount * 60).toDouble(),
      'currency': '',
      'categories': categoryData,
    },

    // RankedBarChartCard
    // 为每个项目分配平分百分比和不同颜色
    'rankedBarChartCard': {
      'title': '$dateRangeLabel排行',
      'items': rankedData,
      'unit': '分钟',
    },
  };
}

// ============================================================
// 习惯统计公共小组件数据提供者
// 配置: habitId
// ============================================================

/// 获取单个习惯在一段时间内的每日数据
Future<List<int>> _getDailyMinutesForHabit(
  String habitId,
  int days,
  dynamic recordController,
) async {
  final records =
      (await recordController.getHabitCompletionRecords(habitId) as List)
          .cast<CompletionRecord>();
  final now = DateTime.now();
  final dailyMinutes = List<int>.filled(days, 0);

  for (final record in records) {
    final daysAgo = now.difference(record.date).inDays;
    if (daysAgo >= 0 && daysAgo < days) {
      dailyMinutes[days - 1 - daysAgo] += record.duration.inMinutes;
    }
  }

  return dailyMinutes;
}

/// 习惯统计公共小组件数据提供者
Future<Map<String, Map<String, dynamic>>> provideHabitStatsWidgets(
  Map<String, dynamic> config,
) async {
  final dynamic plugin = PluginManager.instance.getPlugin('habits');
  if (plugin == null) return {};

  // 尝试从多种格式中提取 habitId
  String? habitId;

  // 格式1: 从 selectedData.data 数组中提取（保存的配置结构）
  if (config.containsKey('selectedData') && config['selectedData'] is Map) {
    final selectedData = config['selectedData'] as Map;
    if (selectedData.containsKey('data') && selectedData['data'] is List) {
      final dataList = selectedData['data'] as List;
      if (dataList.isNotEmpty && dataList[0] is Map) {
        habitId = (dataList[0] as Map)['habitId']?.toString() ??
            (dataList[0] as Map)['id']?.toString();
      }
    }
  }
  // 格式2: 从 data 数组中提取（来自选择器）
  else if (config.containsKey('data') && config['data'] is List) {
    final dataList = config['data'] as List;
    if (dataList.isNotEmpty && dataList[0] is Map) {
      habitId = (dataList[0] as Map)['habitId']?.toString() ??
          (dataList[0] as Map)['id']?.toString();
    }
  }
  // 格式3: 直接包含 habitId（来自自定义表单）
  else if (config.containsKey('habitId')) {
    habitId = config['habitId'] as String?;
  }
  // 格式4: 包含 id 字段（直接从 Habit 对象或 Map 转换来的）
  else if (config.containsKey('id')) {
    habitId = config['id'] as String?;
  }
  // 格式5: 从 rawData 中提取（有些选择器会把原始数据放在 rawData 中）
  else if (config.containsKey('rawData') && config['rawData'] is Map) {
    final rawData = config['rawData'] as Map;
    habitId = rawData['id']?.toString() ?? rawData['habitId']?.toString();
  }

  if (habitId == null || habitId.isEmpty) {
    debugPrint('[provideHabitStatsWidgets] 无法从配置中提取 habitId: $config');
    return {};
  }

  // 使用动态类型避免循环导入
  final habitController = plugin.getHabitController();
  final recordController = plugin.getRecordController();

  final habits = (habitController.getHabits() as List).cast<Habit>();
  final habit = habits.firstWhere(
    (h) => h.id == habitId,
    orElse: () => throw Exception('Habit not found'),
  );

  // 获取统计数据
  final weeklyMinutes = await _getDailyMinutesForHabit(
    habitId,
    7,
    recordController,
  );
  final totalMinutes = await recordController.getTotalDuration(habitId) as int;
  final completionCount =
      await recordController.getCompletionCount(habitId) as int;

  // 获取技能名称
  String? skillName;
  if (habit.skillId != null) {
    try {
      final skill = plugin.getSkillController().getSkillById(habit.skillId!);
      skillName = skill?.title;
    } catch (_) {}
  }

  // 根据习惯生成颜色
  final habitColor = HabitsUtils.generateColorForHabit(habit);

  // 计算周数据归一化 (0-1)
  final maxWeeklyMinutes =
      weeklyMinutes.reduce((a, b) => a > b ? a : b).toDouble();
  final weeklyValues =
      weeklyMinutes
          .map((m) => maxWeeklyMinutes > 0 ? m / maxWeeklyMinutes : 0.0)
          .toList();

  // 计算平均时长
  final avgMinutes =
      weeklyMinutes.isEmpty
          ? 0.0
          : weeklyMinutes.reduce((a, b) => a + b) / weeklyMinutes.length;

  // 星期标签
  final weekDays = ['一', '二', '三', '四', '五', '六', '日'];

  return {
    // MonthlyProgressWithDotsCard - 月度进度圆点卡片
    'monthlyProgressDotsCard': {
      'title': habit.title,
      'subtitle': skillName ?? habit.group ?? '习惯',
      'currentDay': completionCount,
      'totalDays': 30,
      'percentage': (completionCount / 30 * 100).clamp(0, 100).toInt(),
    },

    // StressLevelMonitor (复用为习惯强度监测)
    'stressLevelMonitor': {
      'title': habit.title,
      'currentScore':
          weeklyMinutes.isEmpty
              ? 0.0
              : weeklyMinutes.reduce((a, b) => a + b) / weeklyMinutes.length,
      'status': avgMinutes > 30 ? '完成良好' : (avgMinutes > 0 ? '继续加油' : '记得打卡'),
      'scoreUnit': '分钟',
      'weeklyData':
          weekDays.asMap().entries.map((entry) {
            return {
              'day': weekDays[entry.key],
              'value': weeklyValues[entry.key],
              'isSelected': entry.key == 6, // 选中最后一天（今天）
            };
          }).toList(),
    },

    // SleepTrackingCard (复用为习惯追踪卡片)
    'sleepTrackingCard': {
      'title': habit.title,
      'mainValue': avgMinutes.toDouble() / 60, // 转换为小时
      'statusLabel': skillName ?? habit.group ?? '习惯',
      'unit': 'hr',
      'weeklyProgress':
          weekDays.asMap().entries.map((entry) {
            final minutes = weeklyMinutes[entry.key];
            return {
              'day': weekDays[entry.key],
              'achieved': minutes > 0,
              'progress':
                  maxWeeklyMinutes > 0 ? minutes / maxWeeklyMinutes : 0.0,
            };
          }).toList(),
    },

    // SleepDurationCard (复用为习惯时长卡片)
    'sleepDurationCard': {
      'durationInMinutes': totalMinutes.toInt(),
      'trend':
          weeklyMinutes.isNotEmpty &&
                  weeklyMinutes.last > weeklyMinutes[weeklyMinutes.length - 2]
              ? 'up'
              : 'down',
    },

    // BarChartStatsCard - 柱状图统计卡片
    'barChartStatsCard': {
      'title': habit.title,
      'dateRange': '近7天',
      'averageValue': weeklyMinutes.reduce((a, b) => a + b) / 7,
      'unit': '分钟',
      'icon': 'bar_chart',
      'iconColor': habitColor.value,
      'data': weeklyMinutes.map((m) => m.toDouble()).toList(),
      'labels': weekDays,
      'maxValue':
          (weeklyMinutes.reduce((a, b) => a > b ? a : b) * 1.2)
              .clamp(10, 1000)
              .toDouble(),
    },

    // MiniTrendCard - 迷你趋势卡片
    'miniTrendCard': {
      'title': habit.title,
      'icon': 'monitor_heart',
      'currentValue': avgMinutes,
      'unit': '分钟',
      'subtitle': skillName ?? '本周趋势',
      'weekDays': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      'trendData': weeklyMinutes.map((m) => m.toDouble()).toList(),
    },

    // TrendValueCard - 趋势数值卡片
    'trendValueCard': {
      'value': totalMinutes.toDouble(),
      'unit': '分钟',
      'trendValue':
          weeklyMinutes.isNotEmpty &&
                  weeklyMinutes[weeklyMinutes.length - 2] > 0
              ? (weeklyMinutes.last - weeklyMinutes[weeklyMinutes.length - 2])
                  .toDouble()
              : 0,
      'trendUnit': '分钟',
      'chartData': weeklyMinutes.map((m) => m.toDouble()).toList(),
      'date': '累计$totalMinutes分钟',
      'trendLabel': 'vs 昨天',
    },

    // ModernRoundedBalanceCard - 现代圆角余额卡片
    'modernRoundedBalanceCard': {
      'title': habit.title,
      'balance': totalMinutes.toDouble(),
      'available':
          (habit.durationMinutes > 0
                  ? habit.durationMinutes - totalMinutes % habit.durationMinutes
                  : 0)
              .toDouble(),
      'weeklyData': weeklyMinutes.map((m) => m.toDouble()).toList(),
    },
  };
}
