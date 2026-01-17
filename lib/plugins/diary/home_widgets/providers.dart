/// 日记插件主页小组件数据提供者

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import '../diary_plugin.dart';

/// 公共小组件提供者函数 - 本月日记列表
///
/// 注意：由于 commonWidgetsProvider 需要是同步函数，这里使用 DiaryPlugin 的缓存统计数据。
/// 实际的日记详情数据会在小组件渲染时通过异步方式加载。
Map<String, Map<String, dynamic>> provideMonthlyDiaryListWidgets(
  Map<String, dynamic> data,
) {
  final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
  if (plugin == null) return {};

  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final totalDays = DateTime(year, month + 1, 0).day;

  // 从缓存获取统计数据
  final monthProgress = plugin.getMonthProgressSync();
  final entryCount = monthProgress.$1;
  final totalWordCount = plugin.getMonthWordCountSync();

  // 构建数据（基于缓存统计）
  return {
    // 任务进度列表卡片 - 显示本月日记进度
    'taskProgressList': {
      'title': '本月日记',
      'icon': Icons.book.codePoint,
      'tasks': const [],
      'moreCount': entryCount > 5 ? entryCount - 5 : 0,
    },

    // 观看进度卡片 - 显示本月日记完成进度
    'watchProgressCard': {
      'userName': '本月日记',
      'lastWatched': DateFormat('yyyy年MM月').format(now),
      'enableHeader': false,
      'progressLabel': '已完成天数',
      'currentCount': entryCount,
      'totalCount': totalDays,
      'items': const [],
    },

    // 每周点追踪卡片 - 显示本月每日打卡情况
    'monthlyDotTrackerCard': {
      'title': '本月日记打卡',
      'currentValue': entryCount,
      'totalDays': totalDays,
      'iconCodePoint': Icons.edit_calendar.codePoint,
      'daysData': List.generate(totalDays, (index) {
        return {
          'day': index + 1,
          'isChecked': false,
        };
      }),
    },

    // 任务列表卡片 - 显示本月日记列表
    'taskListCard': {
      'title': '本月日记',
      'count': entryCount,
      'countLabel': '篇日记',
      'items': const [],
      'moreCount': 0,
    },

    // 月度进度圆点卡片 - 与 monthlyDotTrackerCard 类似
    'monthlyProgressDotsCard': {
      'title': '本月日记打卡',
      'currentValue': entryCount,
      'totalDays': totalDays,
      'iconCodePoint': Icons.edit_calendar.codePoint,
      'daysData': List.generate(totalDays, (index) {
        return {
          'day': index + 1,
          'isChecked': false,
        };
      }),
    },

    // 消息列表卡片 - 显示日记摘要列表
    'messageListCard': {
      'featuredMessage': {
        'sender': '我的日记',
        'title': '本月日记',
        'summary': '本月共写了 $entryCount 篇日记，总计 $totalWordCount 字',
        'avatarUrl': '',
      },
      'messages': const [],
    },

    // 彩色标签任务卡片 - 按心情分类显示日记
    'colorTagTaskCard': {
      'taskCount': entryCount,
      'label': '本月日记',
      'tasks': const [],
      'moreCount': 0,
    },

    // 收件箱消息卡片
    'inboxMessageCard': {
      'title': '日记列表',
      'messages': const [],
      'unreadCount': 0,
    },

    // 即将到来的任务小组件 - 显示最近的日记
    'upcomingTasksWidget': {
      'title': '最近日记',
      'taskCount': entryCount.clamp(0, 4),
      'moreCount': (entryCount - 4).clamp(0, 999),
      'tasks': const [],
    },

    // 圆角提醒事项列表 - 显示日记提醒
    'roundedRemindersList': {
      'title': '本月日记',
      'count': entryCount,
      'items': const [],
    },
  };
}

/// 构建本月日记列表通用小组件（根据配置渲染选中的公共小组件）
Widget buildMonthlyDiaryListWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  final selectorConfig =
      config['selectorWidgetConfig'] as Map<String, dynamic>?;
  if (selectorConfig == null) {
    return HomeWidget.buildErrorWidget(
      context,
      '配置错误：缺少 selectorWidgetConfig',
    );
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
    return HomeWidget.buildErrorWidget(
      context,
      '未知的公共小组件类型: $commonWidgetId',
    );
  }

  // 获取元数据以确定默认尺寸
  final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);

  return CommonWidgetBuilder.build(
    context,
    widgetIdEnum,
    commonWidgetProps,
    metadata.defaultSize,
  );
}
