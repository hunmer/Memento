/// 纪念日插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/app_initializer.dart' show navigatorKey;
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../day_plugin.dart';
import '../models/memorial_day.dart';
import 'utils.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
    if (plugin == null) return [];

    final totalCount = plugin.getMemorialDayCount();
    final upcomingDays = plugin.getUpcomingMemorialDays();

    return [
      StatItemData(
        id: 'total_count',
        label: 'day_memorialDays'.tr,
        value: '$totalCount',
        highlight: false,
      ),
      StatItemData(
        id: 'upcoming',
        label: 'day_upcoming'.tr,
        value: upcomingDays.isNotEmpty ? upcomingDays.join('、') : '暂无',
        highlight: upcomingDays.isNotEmpty,
        color: Colors.black87,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 从选择器数据中提取纪念日小组件需要的数据
Map<String, dynamic> extractMemorialDayData(List<dynamic> dataArray) {
  final dayData = dataArray[0];

  // 处理 MemorialDay 对象或 Map
  if (dayData is MemorialDay) {
    return {
      'id': dayData.id,
      'title': dayData.title,
      'targetDate': dayData.targetDate.toIso8601String(),
      'backgroundImageUrl': dayData.backgroundImageUrl,
      'backgroundColor': dayData.backgroundColor.value,
      'daysRemaining': dayData.daysRemaining,
      'daysPassed': dayData.daysPassed,
      'isToday': dayData.isToday,
      'isExpired': dayData.isExpired,
    };
  } else if (dayData is Map<String, dynamic>) {
    return {
      'id': dayData['id'] as String,
      'title': dayData['title'] as String?,
      'targetDate': dayData['targetDate'] as String?,
      'backgroundImageUrl': dayData['backgroundImageUrl'] as String?,
      'backgroundColor': dayData['backgroundColor'] as int?,
      'daysRemaining': dayData['daysRemaining'] as int?,
      'daysPassed': dayData['daysPassed'] as int?,
      'isToday': dayData['isToday'] as bool?,
      'isExpired': dayData['isExpired'] as bool?,
    };
  }

  return {};
}

/// 从选择器数据中提取日期范围值
Map<String, dynamic> extractDateRangeData(List<dynamic> dataArray) {
  // dataArray 包含 SelectableItem 对象，rawData 是 Map
  final selectedItem = dataArray[0];

  Map<String, dynamic>? rangeData;
  if (selectedItem is Map<String, dynamic> && selectedItem.containsKey('rawData')) {
    rangeData = selectedItem['rawData'] as Map<String, dynamic>?;
  } else if (selectedItem is Map<String, dynamic>) {
    rangeData = selectedItem;
  }

  // 默认值：未来7天
  final startDay = rangeData?['startDay'] as int? ?? 0;
  final endDay = rangeData?['endDay'] as int? ?? 7;
  final title = rangeData?['title'] as String? ?? '未来7天';

  // 获取纪念日列表数据
  final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
  final allDays = plugin?.getAllMemorialDays() ?? [];
  final filteredDays = filterMemorialDaysByDaysRange(
    allDays,
    startDay,
    endDay,
  );

  // 将纪念日列表转换为 Map 数组
  final daysList =
      filteredDays.map(memorialDayToListItemData).map((d) => d.toJson()).toList();

  return {
    'startDay': startDay,
    'endDay': endDay,
    'dateRangeLabel': title,
    'daysList': daysList,
    'totalCount': filteredDays.length,
    'todayCount': filteredDays.where((d) => d.isToday).length,
    'upcomingCount':
        filteredDays.where((d) => !d.isExpired && !d.isToday).length,
    'expiredCount': filteredDays.where((d) => d.isExpired).length,
  };
}

/// 公共小组件提供者函数 - 为纪念日提供可用的公共小组件
Future<Map<String, Map<String, dynamic>>> provideMemorialDayCommonWidgets(
  Map<String, dynamic> data,
) async {
  // data 包含：id, title, targetDate, backgroundImageUrl, backgroundColor, daysRemaining, daysPassed, isToday, isExpired
  final title = data['title'] as String? ?? '纪念日';
  final targetDateStr = data['targetDate'] as String?;
  final targetDate =
      targetDateStr != null ? DateTime.tryParse(targetDateStr) : null;
  final backgroundColor = data['backgroundColor'] as int?;
  final daysRemaining = data['daysRemaining'] as int? ?? 0;
  final daysPassed = data['daysPassed'] as int? ?? 0;
  final isToday = data['isToday'] as bool? ?? false;
  final isExpired = data['isExpired'] as bool? ?? false;

  // 计算进度（基于一年365天，取反数作为进度）
  int effectiveDays = isExpired ? daysPassed : daysRemaining;
  final percentage =
      ((365 - effectiveDays) / 365 * 100).clamp(0, 100).toDouble();
  final progress = ((365 - effectiveDays) / 365).clamp(0.0, 1.0);

  // 格式化日期
  final formattedDate =
      targetDate != null ? formatDateLocalized(targetDate) : '';

  // 状态文本
  String statusText;
  if (isToday) {
    statusText = '就是今天！';
  } else if (isExpired) {
    statusText = '已过 $daysPassed 天';
  } else {
    statusText = '剩余 $daysRemaining 天';
  }

  return {
    // 圆形进度卡片：显示纪念日进度
    'circularProgressCard': {
      'title': title,
      'subtitle': statusText,
      'percentage': percentage,
      'progress': progress,
      'progressColor': backgroundColor,
    },

    // 月度进度圆点卡片：显示日期进度
    'monthlyProgressDotsCard': {
      'title': title,
      'subtitle': formattedDate,
      'currentDay': (isExpired ? daysPassed : 365 - daysRemaining) + 1,
      'totalDays': 365,
      'percentage': percentage.toInt(),
      'backgroundColor': backgroundColor ?? const Color(0xFF148690).value,
    },

    // 图标圆形进度卡片：显示倒计时
    'iconCircularProgressCard': {
      'progress': progress,
      'icon': Icons.celebration,
      'title': title,
      'subtitle': statusText,
      'showNotification': isToday,
      'progressColor': backgroundColor,
    },

    // 里程碑卡片：显示纪念日详情
    'milestoneCard': {
      'imageUrl': data['backgroundImageUrl'] as String?,
      'title': title,
      'date': formattedDate,
      'daysCount': isExpired ? daysPassed : daysRemaining,
      'value': isExpired ? '$daysPassed' : '$daysRemaining',
      'unit': isExpired ? '天已过' : '天',
      'suffix': isToday ? '今天' : '',
    },
  };
}

/// 公共小组件提供者函数 - 为日期范围列表提供可用的公共小组件
Future<Map<String, Map<String, dynamic>>> provideDateRangeCommonWidgets(
  Map<String, dynamic> data,
) async {
  // data 包含：startDay, endDay, dateRangeLabel, daysList, totalCount, todayCount, upcomingCount, expiredCount
  final dateRangeLabel = data['dateRangeLabel'] as String? ?? '未来7天';
  final daysList = data['daysList'] as List<dynamic>? ?? [];
  final totalCount = data['totalCount'] as int? ?? 0;
  final todayCount = data['todayCount'] as int? ?? 0;
  final upcomingCount = data['upcomingCount'] as int? ?? 0;

  // 获取前5个纪念日用于列表展示
  final displayDays = daysList.toList();

  // 生成任务列表格式数据（用于任务类小组件）
  final tasks =
      displayDays.map((day) {
        final dayMap = day as Map<String, dynamic>;
        return {
          'title': dayMap['title'] as String? ?? '',
          'subtitle': dayMap['date'] as String? ?? '',
          'status': dayMap['statusText'] as String? ?? '',
          'isCompleted': dayMap['isToday'] as bool? ?? false,
          'color': dayMap['backgroundColor'] as int?,
        };
      }).toList();

  // 生成事件列表格式数据（用于日历/日程类小组件）
  final events =
      displayDays.map((day) {
        final dayMap = day as Map<String, dynamic>;
        return {
          'title': dayMap['title'] as String? ?? '',
          'time': dayMap['date'] as String? ?? '',
          'description': dayMap['statusText'] as String? ?? '',
          'isUrgent': dayMap['isToday'] as bool? ?? false,
        };
      }).toList();

  return {
    // 任务列表卡片：显示纪念日列表
    'taskListCard': {
      'icon': Icons.celebration,
      'iconBackgroundColor': 0xFF148690,
      'count': totalCount,
      'countLabel': 'day_memorialDays'.tr,
      'items': tasks.map((t) => '${t['title']} (${t['status']})').toList(),
      'moreCount': totalCount > 5 ? totalCount - 5 : 0,
    },

    // 任务进度卡片：显示纪念日进度
    'taskProgressCard': {
      'title': dateRangeLabel,
      'subtitle': 'day_memorialDays'.tr,
      'completedTasks': todayCount,
      'totalTasks': totalCount,
      'pendingTasks': tasks.map((t) => t['title'] as String).toList(),
    },

    // 环形指标卡片：显示纪念日列表
    'circularMetricsCard': {
      'title': dateRangeLabel,
      'metrics':
          displayDays.map((day) {
            final dayMap = day as Map<String, dynamic>;
            final colorValue =
                dayMap['backgroundColor'] as int? ?? 0xFF148690;
            return {
              'icon': Icons.celebration.codePoint,
              'value': dayMap['title'] as String? ?? '',
              'label': dayMap['date'] as String? ?? '',
              'progress': 1.0,
              'color': colorValue,
            };
          }).toList(),
    },

    // 日历事件小组件：显示纪念日日历
    'eventCalendarWidget': {
      'day': DateTime.now().day,
      'weekday': getWeekday(DateTime.now().weekday),
      'month': getMonth(DateTime.now().month),
      'eventCount': totalCount,
      'weekDates': getWeekDates(),
      'weekStartDay': 1,
      'reminder': dateRangeLabel,
      'reminderEmoji': '📅',
      'events':
          events.map((e) {
            return {
              'title': e['title'] as String? ?? '',
              'time': e['time'] as String? ?? '',
              'duration': '',
              'color': 0xFF525EAF,
              'iconColor': 0xFF6264A7,
            };
          }).toList(),
    },

    // 每日事件卡片：显示纪念日事件列表
    'dailyEventsCard': {
      'weekday': getWeekday(DateTime.now().weekday),
      'day': DateTime.now().day,
      'events':
          events.map((e) {
            return {
              'title': e['title'] as String? ?? '',
              'time': e['time'] as String? ?? '',
              'colorValue': 0xFFE8A546,
              'backgroundColorLightValue': 0xFFFFF9F0,
              'backgroundColorDarkValue': 0xFF3d342b,
              'textColorLightValue': 0xFF5D4037,
              'textColorDarkValue': 0xFFFFE0B2,
              'subtextLightValue': 0xFF8D6E63,
              'subtextDarkValue': 0xFFD7CCC8,
            };
          }).toList(),
    },

    // 每日日程卡片：显示纪念日日程
    'dailyScheduleCard': {
      'todayDate': dateRangeLabel,
      'todayEvents': events,
      'tomorrowEvents': [],
    },

    // 彩色标签任务卡片：显示彩色标签的纪念日列表
    'colorTagTaskCard': {
      'taskCount': totalCount,
      'label': dateRangeLabel,
      'tasks':
          tasks.map((t) {
            return {
              'title': t['title'] as String? ?? '',
              'color': t['color'] as int? ?? 0xFF3B82F6,
              'tag': t['status'] as String? ?? '',
            };
          }).toList(),
      'moreCount': totalCount > 3 ? totalCount - 3 : 0,
    },

    // 即将到来任务小组件：显示即将到来的纪念日
    'upcomingTasksWidget': {
      'taskCount': upcomingCount,
      'tasks':
          tasks.map((t) {
            return {
              'title': t['title'] as String? ?? '',
              'subtitle': t['subtitle'] as String? ?? '',
              'status': t['status'] as String? ?? '',
              'isCompleted': t['isCompleted'] as bool? ?? false,
            };
          }).toList(),
      'moreCount': totalCount > 3 ? totalCount - 3 : 0,
    },

    // 圆角任务列表卡片：显示圆角样式的纪念日列表
    'roundedTaskListCard': {
      'title': dateRangeLabel,
      'date': dateRangeLabel,
      'tasks':
          tasks.map((t) {
            return {
              'title': t['title'] as String? ?? '',
              'subtitle': t['subtitle'] as String? ?? '',
              'date': t['date'] as String? ?? '',
            };
          }).toList(),
      'totalCount': totalCount,
    },

    // 圆角提醒事项列表：显示纪念日提醒列表
    'roundedRemindersList': {
      'title': dateRangeLabel,
      'items':
          displayDays.map((day) {
            final dayMap = day as Map<String, dynamic>;
            return {
              'text': '${dayMap['title']} (${dayMap['statusText']})',
              'isCompleted': dayMap['isToday'] as bool? ?? false,
            };
          }).toList(),
    },
  };
}

/// 导航到纪念日主页面
void navigateToDayPage(BuildContext context, SelectorResult result) {
  NavigationHelper.pushNamed(context, '/day');
}

/// 导航到纪念日详情页
void navigateToMemorialDay(
  BuildContext context,
  SelectorResult result,
) {
  final data =
      result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : {};
  final dayId = data['id'] as String?;

  // 使用 navigatorKey.currentContext 确保导航正常工作
  final navContext = navigatorKey.currentContext ?? context;

  NavigationHelper.pushNamed(
    navContext,
    '/day',
    arguments: {'memorialDayId': dayId},
  );
}
