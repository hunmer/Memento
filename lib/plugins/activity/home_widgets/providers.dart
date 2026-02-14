/// 活动插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:intl/intl.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import '../activity_plugin.dart';
import '../models/activity_record.dart';
import 'data.dart';
import 'utils.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin =
        PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
    if (plugin == null) return [];

    final activityCount = plugin.getTodayActivityCountSync();
    final activityDuration = plugin.getTodayActivityDurationSync();
    final remainingTime = plugin.getTodayRemainingTime();

    return [
      StatItemData(
        id: 'today_activities',
        label: 'activity_todayActivities'.tr,
        value: '$activityCount',
        highlight: activityCount > 0,
        color: Colors.pink,
      ),
      StatItemData(
        id: 'today_duration',
        label: 'activity_todayDuration'.tr,
        value: '${(activityDuration / 60).toStringAsFixed(1)}H',
        highlight: false,
      ),
      StatItemData(
        id: 'remaining_time',
        label: 'activity_remainingTime'.tr,
        value: '${(remainingTime / 60).toStringAsFixed(1)}H',
        highlight: remainingTime < 120,
        color: Colors.red,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 构建 2x2 详细卡片组件
Widget buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
  try {
    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'activity_added',
            'activity_updated',
            'activity_deleted',
          ],
          onEvent: () => setState(() {}),
          child: buildOverviewContent(context, widgetConfig),
        );
      },
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 构建概览小组件内容（获取最新数据）
Widget buildOverviewContent(
  BuildContext context,
  PluginWidgetConfig widgetConfig,
) {
  // 获取可用的统计项数据（每次重建时重新获取）
  final availableItems = getAvailableStats(context);

  // 使用通用小组件
  return GenericPluginWidget(
    pluginId: 'activity',
    pluginName: 'activity_name'.tr,
    pluginIcon: Icons.access_time,
    pluginDefaultColor: Colors.pink,
    availableItems: availableItems,
    config: widgetConfig,
  );
}

/// 构建公共小组件显示
Widget buildCommonWidgetsWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  final selectorConfig =
      config['selectorWidgetConfig'] as Map<String, dynamic>?;
  if (selectorConfig == null) {
    return HomeWidget.buildErrorWidget(context, '配置错误：缺少 selectorWidgetConfig');
  }

  final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
  final commonWidgetProps =
      selectorConfig['commonWidgetProps'] as Map<String, dynamic>?;

  if (commonWidgetId == null || commonWidgetProps == null) {
    return HomeWidget.buildErrorWidget(
      context,
      '配置错误：缺少 commonWidgetId 或 commonWidgetProps',
    );
  }

  // 查找对应的 CommonWidgetId 枚举
  final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
  if (widgetIdEnum == null) {
    return HomeWidget.buildErrorWidget(context, '未知的公共小组件类型: $commonWidgetId');
  }

  // 获取元数据以确定默认尺寸
  final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);

  return CommonWidgetBuilder.build(
    context,
    widgetIdEnum,
    commonWidgetProps,
    metadata.defaultSize,
    inline: true,
  );
}

/// 公共小组件提供者函数（同步版本）
Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  // 获取今日活动数据
  final plugin =
      PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
  if (plugin == null) return {};

  final now = DateTime.now();

  // 同步获取今日活动（使用缓存）
  final todayActivities = plugin.getTodayActivitiesSync();

  // 同步获取昨日活动（使用缓存）
  final yesterdayActivities = plugin.getYesterdayActivitiesSync();

  // 计算今日统计数据
  final todayActivityCount = todayActivities.length;
  final todayDurationMinutes = todayActivities.fold<int>(
    0,
    (sum, a) => sum + a.durationInMinutes,
  );
  final remainingMinutes = plugin.getTodayRemainingTime();

  // 按标签统计
  final tagStats = <String, int>{};
  for (final activity in todayActivities) {
    for (final tag in activity.tags) {
      tagStats[tag] = (tagStats[tag] ?? 0) + activity.durationInMinutes;
    }
  }

  // 按标签分类活动
  final activitiesByTag = <String, List<ActivityRecord>>{};
  for (final activity in todayActivities) {
    for (final tag in activity.tags) {
      activitiesByTag.putIfAbsent(tag, () => []).add(activity);
    }
  }

  // 计算今日活动中的最长时长
  final maxDurationMinutes =
      todayActivities.isEmpty
          ? 60.0
          : todayActivities
              .map((a) => a.durationInMinutes.toDouble())
              .reduce((a, b) => a > b ? a : b);

  return {
    // 分段进度卡片：按标签统计时长
    'segmentedProgressCard': {
      'title': '今日活动',
      'subtitle': '$todayActivityCount个活动',
      'currentValue': todayDurationMinutes.toDouble(),
      'targetValue': (12 * 60).toDouble(), // 12小时目标
      'unit': '分钟',
      'segments':
          tagStats.entries
              .map(
                (e) => {
                  'label': e.key,
                  'value': e.value.toDouble(),
                  'display': formatDurationForDisplay(e.value),
                  'color': getColorFromTag(e.key).value,
                },
              )
              .toList(),
    },

    // 任务进度卡片：显示今日活动进度
    'taskProgressCard': {
      'title': '今日活动',
      'subtitle': '$todayActivityCount个记录',
      'completedTasks': now.hour,
      'totalTasks': 24,
      'progressLabel': '今日时间',
      'pendingLabel': '活动列表',
      'maxPendingTasks': null,
      'pendingTasks':
          todayActivities
              .map(
                (a) =>
                    '${a.title.isEmpty ? '未命名活动' : a.title} · ${formatTimeRangeStatic(a.startTime, a.endTime)}',
              )
              .toList(),
    },

    // 营养进度卡片：左侧今日剩余时间，右侧活动列表
    'nutritionProgressCard': {
      'leftData': {
        'current': (24 * 60 - remainingMinutes).toDouble(),
        'total': (24 * 60).toDouble(),
        'unit': '分钟',
      },
      'leftConfig': {
        'icon': '⏰',
        'label': '今日剩余',
        'subtext': '${(remainingMinutes / 60).toStringAsFixed(1)}小时',
      },
      'rightItems':
          todayActivities
              .take(4)
              .map(
                (a) => {
                  'icon': '📝',
                  'name': a.title.isEmpty ? '未命名活动' : a.title,
                  'current': a.durationInMinutes.toDouble(),
                  'total': maxDurationMinutes, // 使用今日最长活动时长作为总值
                  'color': Colors.blue.value,
                  'subtitle':
                      '${formatTimeStatic(a.startTime)} - ${formatTimeStatic(a.endTime)}',
                },
              )
              .toList(),
    },

    // 观看进度卡片：显示活动列表
    'watchProgressCard': {
      'userName': '今日活动',
      'lastWatched': '',
      'enableHeader': false,
      'progressLabel': '已用时间',
      'currentCount': now.hour,
      'totalCount': 24,
      'items':
          todayActivities
              .map(
                (a) => {
                  'title': a.title.isEmpty ? '未命名活动' : a.title,
                  'subtitle':
                      '${formatTimeStatic(a.startTime)} - ${formatTimeStatic(a.endTime)}',
                  'thumbnailUrl': null,
                },
              )
              .toList(),
    },

    // 每日日程卡片：今日活动和昨日活动
    'dailyScheduleCard': {
      'todayDate': '${now.month}月${now.day}日',
      'todayEvents':
          todayActivities.map((a) => convertActivityToEventData(a)).toList(),
      'tomorrowEvents':
          yesterdayActivities
              .map((a) => convertActivityToEventData(a))
              .toList(),
    },

    // 支出分类环形图：按标签统计活动时长
    'expenseDonutChart': {
      'badgeLabel': '活动',
      'timePeriod': '${now.month}月${now.day}日',
      'totalAmount': todayDurationMinutes.toDouble() / 60,
      'totalUnit': '小时',
      'categories':
          tagStats.entries
              .map(
                (e) => {
                  'label': e.key,
                  'percentage':
                      todayDurationMinutes > 0
                          ? (e.value / todayDurationMinutes * 100)
                          : 0.0,
                  'color': getColorFromTag(e.key).value,
                  'subtitle': formatActivitiesTimeRange(
                    activitiesByTag[e.key] ?? [],
                  ),
                },
              )
              .toList(),
    },

    // 任务列表卡片
    'taskListCard': {
      'title': '今日活动',
      'count': todayActivityCount,
      'countLabel': '个活动',
      'items':
          todayActivities
              .map((a) => a.title.isEmpty ? '未命名活动' : a.title)
              .toList(),
      'moreCount': 0,
    },

    // 彩色标签任务列表卡片
    'colorTagTaskCard': {
      'taskCount': todayActivityCount,
      'label': '今日活动',
      'tasks':
          todayActivities.map((a) {
            final primaryTag = a.tags.isNotEmpty ? a.tags.first : '默认';
            final timeRange = formatTimeRangeStatic(a.startTime, a.endTime);
            return {
              'title': '($timeRange)',
              'color': getColorFromTag(primaryTag).value,
              'tag': a.title.isEmpty ? '未命名活动' : a.title,
            };
          }).toList(),
      'moreCount': 0,
    },

    // 即将到来的任务小组件：显示接下来的活动
    'upcomingTasksWidget': {
      'title': '活动',
      'taskCount': todayActivityCount,
      'moreCount': 0,
      'tasks':
          todayActivities
              .take(4)
              .map(
                (a) => {
                  'title': a.title.isEmpty ? '未命名活动' : a.title,
                  'color':
                      a.tags.isNotEmpty
                          ? getColorFromTag(a.tags.first).value
                          : Colors.pink.value,
                  'tag': formatTimeRangeStatic(a.startTime, a.endTime),
                },
              )
              .toList(),
    },

    // 圆角任务列表卡片
    'roundedTaskListCard': {
      'headerText': '今日活动',
      'tasks':
          todayActivities
              .map(
                (a) => {
                  'title': a.title.isEmpty ? '未命名活动' : a.title,
                  'subtitle': formatTimeRangeStatic(a.startTime, a.endTime),
                  'date': '${now.month}月${now.day}日',
                },
              )
              .toList(),
    },

    // 圆角提醒事项列表
    'roundedRemindersList': {
      'title': '今日活动',
      'count': todayActivityCount,
      'items':
          todayActivities
              .map(
                (a) => {
                  'text': a.title.isEmpty ? '未命名活动' : a.title,
                  'isCompleted': true,
                },
              )
              .toList(),
    },

    // 现代圆角消费卡片：显示活动时长
    'modernRoundedSpendingWidget': {
      'title': '今日活动',
      'currentAmount': todayDurationMinutes.toDouble(),
      'budgetAmount': (12 * 60).toDouble(), // 12小时目标
      'unit': '分钟',
      'categories':
          tagStats.entries
              .map(
                (e) => {
                  'name': e.key,
                  'amount': e.value.toDouble(),
                  'color': getColorFromTag(e.key).value,
                },
              )
              .toList(),
      'categoryItems':
          activitiesByTag.entries
              .map(
                (e) => {
                  'categoryName': e.key,
                  'items':
                      e.value
                          .take(5)
                          .map(
                            (a) => {
                              'title': a.title.isEmpty ? '未命名活动' : a.title,
                              'subtitle': '${a.durationInMinutes}分钟',
                            },
                          )
                          .toList(),
                },
              )
              .toList(),
    },

    // 分类堆叠消费卡片
    'categoryStackWidget': {
      'title': '今日活动分布',
      'currentAmount': todayDurationMinutes.toDouble(),
      'targetAmount': (12 * 60).toDouble(),
      'categories':
          tagStats.entries
              .map(
                (e) => {
                  'name': e.key,
                  'amount': e.value.toDouble(),
                  'color': getColorFromTag(e.key).value,
                },
              )
              .toList(),
    },

    // 时间线日程卡片：显示昨天和今天的活动
    'timelineScheduleCard': buildTimelineScheduleCardData(
      todayActivities,
      yesterdayActivities,
      now,
    ),

    // 活动热力图卡片
    'activityHeatmapCard': buildHeatmapCardData(todayActivities, data),

    // 今日活动统计卡片
    'activityTodayPieChartCard': {
      'tagStats': tagStats,
      'totalDuration': todayDurationMinutes,
    },
  };
}

/// 构建活动热力图卡片数据
Map<String, dynamic> buildHeatmapCardData(
  List<ActivityRecord> activities,
  Map<String, dynamic> selectorData,
) {
  // 获取时间粒度（从选择器数据或使用默认值60分钟）
  int timeGranularity = 60;
  if (selectorData.containsKey('timeGranularity')) {
    timeGranularity = selectorData['timeGranularity'] as int? ?? 60;
  }

  // 计算时间槽数据
  final timeSlots = calculateTimeSlotData(activities, timeGranularity);

  // 计算总时长
  final totalMinutes = activities.fold<int>(
    0,
    (sum, a) => sum + a.durationInMinutes,
  );

  // 计算活跃小时数
  final activeHours = calculateActiveHours(activities);

  // 转换时间槽数据为 Map 格式
  final timeSlotsList =
      timeSlots
          .map(
            (slot) => {
              'hour': slot.hour,
              'minute': slot.minute,
              'durationMinutes': slot.durationMinutes,
              'tagDurations': slot.tagDurations,
            },
          )
          .toList();

  return {
    'timeGranularity': timeGranularity,
    'timeSlots': timeSlotsList,
    'totalMinutes': totalMinutes,
    'activeHours': activeHours,
  };
}

/// 计算指定时间粒度的数据（用于公共组件）
List<TimeSlotDataWrapper> calculateTimeSlotData(
  List<ActivityRecord> activities,
  int granularityMinutes,
) {
  final totalSlots = (24 * 60) ~/ granularityMinutes;
  final slots = <TimeSlotDataWrapper>[];
  final now = DateTime.now();

  for (int i = 0; i < totalSlots; i++) {
    final hour = (i * granularityMinutes) ~/ 60;
    final minute = (i * granularityMinutes) % 60;

    final slotStart = DateTime(now.year, now.month, now.day, hour, minute);
    final slotEnd = slotStart.add(Duration(minutes: granularityMinutes));

    int totalMinutes = 0;
    final Map<String, int> tagDurations = {};

    for (final activity in activities) {
      if (activity.startTime.isBefore(slotEnd) &&
          activity.endTime.isAfter(slotStart)) {
        final effectiveStart =
            activity.startTime.isBefore(slotStart)
                ? slotStart
                : activity.startTime;
        final effectiveEnd =
            activity.endTime.isAfter(slotEnd) ? slotEnd : activity.endTime;

        if (effectiveEnd.isAfter(effectiveStart)) {
          final minutes = effectiveEnd.difference(effectiveStart).inMinutes;
          totalMinutes += minutes;

          // 收集每个标签的时长
          for (final tag in activity.tags) {
            tagDurations[tag] = (tagDurations[tag] ?? 0) + minutes;
          }
        }
      }
    }

    slots.add(
      TimeSlotDataWrapper(
        hour: hour,
        minute: minute,
        durationMinutes: totalMinutes,
        tagDurations: tagDurations,
      ),
    );
  }

  return slots;
}

/// 计算活跃小时数（用于公共组件）
int calculateActiveHours(List<ActivityRecord> activities) {
  final activeHours = <int>{};
  for (final activity in activities) {
    final startHour = activity.startTime.hour;
    final endHour = activity.endTime.hour;

    for (int h = startHour; h <= endHour; h++) {
      final hourStart = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
        h,
        0,
      );
      final hourEnd = hourStart.add(const Duration(hours: 1));

      if (activity.startTime.isBefore(hourEnd) &&
          activity.endTime.isAfter(hourStart)) {
        activeHours.add(h);
      }
    }
  }
  return activeHours.length;
}

/// 七天活动统计图表小组件提供者
Future<Map<String, Map<String, dynamic>>> provideWeeklyChartWidgets(
  Map<String, dynamic> data,
) async {
  final plugin =
      PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
  if (plugin == null) return {};

  // 获取过去7天的活动数据
  final now = DateTime.now();
  final sevenDaysData = <DayActivityData>[];
  final weekDayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  final weekDayLabelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final activities = plugin.getActivitiesForDateSync(date);
    final totalMinutes = activities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );
    sevenDaysData.add(
      DayActivityData(
        date: date,
        totalMinutes: totalMinutes,
        activityCount: activities.length,
      ),
    );
  }

  // 计算统计数据
  final totalWeekMinutes = sevenDaysData.fold<int>(
    0,
    (sum, d) => sum + d.totalMinutes,
  );
  final avgMinutes = totalWeekMinutes / 7;
  final maxMinutes = sevenDaysData
      .map((d) => d.totalMinutes)
      .reduce((a, b) => a > b ? a : b);

  // 为各种图表组件准备数据
  final weeklyDurations =
      sevenDaysData.map((d) => d.totalMinutes.toDouble()).toList();
  final weeklyNormalized =
      maxMinutes > 0
          ? weeklyDurations.map((d) => d / maxMinutes).toList()
          : List.filled(7, 0.0);

  // 格式化日期范围
  final startDate = DateFormat('MM月dd日').format(sevenDaysData.first.date);
  final endDate = DateFormat('MM月dd日').format(sevenDaysData.last.date);

  // 获取今天和昨天的数据用于对比
  final todayMinutes = sevenDaysData.last.totalMinutes.toDouble();
  final yesterdayMinutes =
      sevenDaysData[sevenDaysData.length - 2].totalMinutes.toDouble();
  final changePercent =
      yesterdayMinutes > 0
          ? ((todayMinutes - yesterdayMinutes) / yesterdayMinutes * 100).floor()
          : 0.0;

  return {
    // StressLevelMonitor (CardBarChartMonitor) - 压力水平监测样式
    'stressLevelMonitor': {
      'title': '活动时长',
      'icon': 'timeline',
      'currentScore': avgMinutes / 60, // 转换为小时
      'status': getActivityStatus(avgMinutes),
      'scoreUnit': '小时/天',
      'weeklyData':
          sevenDaysData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return {
              'day':
                  weekDayLabelsEn[(now
                              .subtract(Duration(days: 6 - index))
                              .weekday -
                          1) %
                      7],
              'value': maxMinutes > 0 ? data.totalMinutes / maxMinutes : 0.0,
              'isSelected': index == 6,
            };
          }).toList(),
    },

    // LineChartTrendCard - 折线图趋势卡片
    'lineChartTrendCard': {
      'title': '活动时长趋势',
      'subtitle': '$startDate - $endDate',
      'date': DateFormat('yyyy-MM-dd').format(now),
      'totalValue': totalWeekMinutes,
      'changePercent': changePercent,
      'value': avgMinutes / 60, // 平均值（小时）
      'label': '日均活动',
      'unit': '小时',
      'inline': false,
      'dataPoints':
          sevenDaysData.map((d) {
            final normalized =
                maxMinutes > 0 ? d.totalMinutes / maxMinutes : 0.0;
            return normalized * 100; // 转换为0-100的百分比
          }).toList(),
    },

    // SmoothLineChartCard - 平滑折线图卡片
    'smoothLineChartCard': {
      'title': '活动时长',
      'subtitle': '近7天统计',
      'date': DateFormat('MM月dd日').format(now),
      'currentValue': avgMinutes.toStringAsFixed(1),
      'targetValue': (12 * 60).toStringAsFixed(0), // 12小时目标
      'unit': '分钟',
      'maxValue': 120.0, // 匹配 y 值范围 0-120
      'timeLabels': weekDayLabels, // 星期标签
      'dataPoints':
          sevenDaysData.asMap().entries.map((entry) {
            final value = entry.value.totalMinutes;
            final normalized = maxMinutes > 0 ? value / maxMinutes : 0.0;
            return {
              'x': (entry.key * 53.33).clamp(0.0, 320.0),
              'y': (120 - normalized * 100).clamp(0.0, 120.0),
            };
          }).toList(),
    },

    // BarChartStatsCard - 柱状图统计卡片
    'barChartStatsCard': {
      'title': '活动统计',
      'dateRange': '$startDate - $endDate',
      'averageValue': avgMinutes / 60, // 转换为小时
      'unit': '小时',
      'icon': 'timeline',
      'iconColor': Colors.pink.value,
      'data': sevenDaysData.map((d) => d.totalMinutes / 60).toList(),
      'labels': List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return weekDayLabels[(date.weekday - 1) % 7];
      }),
      'maxValue': maxMinutes / 60, // 转换为小时
    },

    // WeeklyBarsCard - 周柱状图卡片
    'weeklyBarsCard': {
      'title': '周活动统计',
      'icon': 'bar_chart',
      'currentValue': avgMinutes / 60, // 转为小时
      'unit': '小时',
      'status': '日均',
      'dailyValues':
          maxMinutes > 0
              ? sevenDaysData.map((d) => d.totalMinutes / maxMinutes).toList()
              : List.filled(7, 0.0),
    },

    // ExpenseComparisonChart - 支出对比图表
    'expenseComparisonChart': {
      'title': '活动对比',
      'currentAmount': todayMinutes / 60, // 转为小时
      'unit': '小时',
      'changePercent': changePercent,
      'maxValue': 24.0, // 24小时
      'labels': List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return DateFormat('dd').format(date);
      }),
      'dailyData':
          sevenDaysData.asMap().entries.map((entry) {
            return {
              'lastMonth':
                  entry.key > 0
                      ? sevenDaysData[entry.key - 1].totalMinutes / 60
                      : 0.0,
              'currentMonth': entry.value.totalMinutes / 60,
            };
          }).toList(),
    },

    // BloodPressureTracker (DualValueTrackerCardWrapper) - 双数值追踪卡片
    'bloodPressureTracker': {
      'title': '活动统计',
      'primaryValue': (todayMinutes / 60).toInt(),
      'secondaryValue': (avgMinutes / 60).toInt(),
      'status': getActivityStatus(avgMinutes),
      'unit': '小时',
      'icon': 'timeline',
      'weekData':
          sevenDaysData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final normalized =
                maxMinutes > 0 ? data.totalMinutes / maxMinutes : 0.0;
            return {
              'label':
                  weekDayLabelsEn[(now
                              .subtract(Duration(days: 6 - index))
                              .weekday -
                          1) %
                      7],
              'normalPercent': normalized,
              'elevatedPercent': 0.0,
            };
          }).toList(),
    },

    // TrendLineChartCard (TrendLineChartCardWrapper) - 趋势折线图卡片
    'trendLineChartCard': {
      'title': '活动趋势',
      'icon': 'show_chart',
      'value': avgMinutes / 60, // 转为小时
      'dataPoints':
          sevenDaysData.asMap().entries.map((entry) {
            final value = entry.value.totalMinutes;
            final normalized = maxMinutes > 0 ? value / maxMinutes : 0.0;
            return {
              'x': (entry.key * 53.33).clamp(0.0, 320.0),
              'y': (120 - normalized * 100).clamp(0.0, 120.0),
            };
          }).toList(),
      'timeLabels':
          sevenDaysData.asMap().entries.map((entry) {
            return weekDayLabelsEn[(now
                        .subtract(Duration(days: 6 - entry.key))
                        .weekday -
                    1) %
                7];
          }).toList(),
      'primaryColor': Colors.pink.value,
      'valueColor': Colors.pinkAccent.value,
    },

    // ModernRoundedBalanceCard - 现代圆角余额卡片
    'modernRoundedBalanceCard': {
      'title': '活动总时长',
      'balance': totalWeekMinutes / 60, // 转换为小时
      'available': avgMinutes / 60, // 平均时长
      'weeklyData': weeklyNormalized,
    },
  };
}

/// 提供标签周统计小组件数据（供选择器页面使用）（异步版本）
Future<Map<String, Map<String, dynamic>>> provideTagWeeklyChartWidgets(
  Map<String, dynamic> config,
) async {
  // 从 config['data'] 数组中提取 tag
  final dataArray = config['data'] as List<dynamic>?;
  String? tag;

  if (dataArray != null && dataArray.isNotEmpty) {
    final firstItem = dataArray[0];
    if (firstItem is Map<String, dynamic>) {
      tag = firstItem['tag'] as String?;
    }
  }

  // 如果没有标签数据，返回空数据（这会显示未选择标签的提示）
  if (tag == null) {
    return {};
  }

  final tagColor = getColorFromTag(tag);
  // CommonWidgetsProvider 没有 BuildContext，使用默认颜色值
  const primaryColorValue = 0xFFE91E63; // 默认粉色
  final primaryColorString = primaryColorValue.toString();

  final plugin =
      PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
  final now = DateTime.now();

  // 获取7天数据
  final sevenDaysData = <DayActivityData>[];
  if (plugin == null) {
    return {};
  }
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final allActivities = plugin.getActivitiesForDateSync(date);
    final filteredActivities =
        allActivities.where((a) => a.tags.contains(tag)).toList();
    final totalMinutes = filteredActivities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );
    sevenDaysData.add(
      DayActivityData(
        date: date,
        totalMinutes: totalMinutes,
        activityCount: filteredActivities.length,
      ),
    );
  }

  final totalMinutes = sevenDaysData.fold<int>(
    0,
    (sum, d) => sum + d.totalMinutes,
  );
  final avgMinutes = totalMinutes / 7;
  final maxMinutes = sevenDaysData
      .map((d) => d.totalMinutes)
      .reduce((a, b) => a > b ? a : b);
  final weeklyDurations =
      sevenDaysData.map((d) => d.totalMinutes.toDouble()).toList();
  final weeklyNormalized =
      maxMinutes > 0
          ? weeklyDurations.map((d) => d / maxMinutes).toList()
          : List.filled(7, 0.0);

  final todayMinutes = sevenDaysData.last.totalMinutes.toDouble();
  final yesterdayMinutes =
      sevenDaysData[sevenDaysData.length - 2].totalMinutes.toDouble();
  final changePercent =
      yesterdayMinutes > 0
          ? ((todayMinutes - yesterdayMinutes) / yesterdayMinutes * 100).floor()
          : 0;

  final startDate = DateFormat('MM月dd日').format(sevenDaysData.first.date);
  final endDate = DateFormat('MM月dd日').format(sevenDaysData.last.date);

  // 确保 weeklyNormalized 有7个元素
  final normalizedData =
      weeklyNormalized.isNotEmpty ? weeklyNormalized : List.filled(7, 0.0);
  final chartDataForCards =
      normalizedData.isNotEmpty
          ? normalizedData
          : [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];

  return {
    'miniTrendCard': {
      'title': '日均活动时长',
      'tag': tag,
      'tagColor': tagColor.value,
      'primaryColor': primaryColorValue,
      'currentValue': avgMinutes,
      'unit': '分钟',
      'trendData': chartDataForCards,
      'weekDayLabels': ['一', '二', '三', '四', '五', '六', '日'],
    },
    'trendValueCard': {
      'title': '$tag 活动趋势',
      'tag': tag,
      'primaryColor': primaryColorString,
      'value': avgMinutes,
      'unit': '分钟/天',
      'changePercent': changePercent,
      'chartData': chartDataForCards.map((v) => v * 100).toList(),
      'dateRange': '$startDate - $endDate',
    },
    'weeklyBarsCard': {
      'title': '$tag 周统计',
      'tag': tag,
      'primaryColor': primaryColorValue,
      'currentValue': avgMinutes,
      'unit': '分钟',
      'dailyValues': chartDataForCards,
      'weekDayLabels': ['一', '二', '三', '四', '五', '六', '日'],
    },
    'earningsTrendCard': {
      'title': '$tag 总时长',
      'tag': tag,
      'primaryColor': primaryColorValue,
      'value': totalMinutes / 60,
      'currency': '小时',
      'changePercent': changePercent,
      'chartData':
          weeklyDurations.isNotEmpty
              ? weeklyDurations.map((d) {
                return maxMinutes > 0
                    ? (d / maxMinutes * 100).clamp(0.0, 100.0)
                    : 0.0;
              }).toList()
              : List.filled(7, 0.0),
    },
    'spendingTrendChart': {
      'title': '$tag 对比趋势',
      'tag': tag,
      'primaryColor': primaryColorValue,
      'dateRange': '$startDate - $endDate',
      'currentMonthData':
          weeklyDurations.isNotEmpty ? weeklyDurations : List.filled(7, 0.0),
      'previousMonthData': List.generate(7, (index) {
        return index > 0 ? weeklyDurations[index - 1] * 0.8 : 0.0;
      }),
      'maxValue': maxMinutes,
    },
  };
}

/// 构建标签周统计通用小组件（根据配置渲染选中的公共小组件）
Widget buildTagCommonWidget(BuildContext context, Map<String, dynamic> config) {
  return buildCommonWidgetsWidget(context, config);
}
