/// 日记插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import '../diary_plugin.dart';
import '../models/diary_entry.dart';
import '../utils/diary_utils.dart';

/// 公共小组件提供者函数 - 本月日记列表
///
/// 异步加载本月日记数据，返回可用的公共小组件配置
Future<Map<String, Map<String, dynamic>>> provideMonthlyDiaryListWidgets(
  Map<String, dynamic> data,
) async {
  final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
  if (plugin == null) return {};

  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final totalDays = DateTime(year, month + 1, 0).day;

  // 异步加载所有日记条目
  final allEntries = await DiaryUtils.loadDiaryEntries();

  // 过滤本月的日记
  final monthlyEntries = <DateTime, DiaryEntry>{};
  for (final entry in allEntries.entries) {
    if (entry.key.year == year && entry.key.month == month) {
      monthlyEntries[entry.key] = entry.value;
    }
  }

  final entryCount = monthlyEntries.length;

  // 计算统计数据
  final totalWordCount = monthlyEntries.values.fold<int>(
    0,
    (sum, e) => sum + (e.content.length),
  );

  // 按心情统计
  final moodStats = <String, int>{};
  for (final entry in monthlyEntries.values) {
    if (entry.mood != null && entry.mood!.isNotEmpty) {
      moodStats[entry.mood!] = (moodStats[entry.mood!] ?? 0) + 1;
    }
  }

  // 按日期排序（倒序）
  final sortedEntries =
      monthlyEntries.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

  return {
    // 任务进度列表卡片 - 显示本月日记进度
    'taskProgressList': {
      'title': '本月日记',
      'icon': Icons.book.codePoint,
      'tasks':
          sortedEntries.take(5).map((e) {
            final dateStr = DateFormat('MM月dd日').format(e.key);
            final wordCount = e.value.content.length;
            final progress =
                wordCount > 500 ? 1.0 : (wordCount / 500).clamp(0.0, 1.0);
            String status;
            if (wordCount >= 500) {
              status = 'completed';
            } else if (wordCount >= 200) {
              status = 'inProgress';
            } else {
              status = 'started';
            }
            return {
              'title': e.value.title.isNotEmpty ? e.value.title : '无标题日记',
              'time': dateStr,
              'progress': progress,
              'status': status,
            };
          }).toList(),
      'moreCount': (entryCount - 5).clamp(0, 999),
    },

    // 观看进度卡片 - 显示本月日记完成进度
    'watchProgressCard': {
      'userName': '本月日记',
      'lastWatched': DateFormat('yyyy年MM月').format(now),
      'enableHeader': false,
      'progressLabel': '已完成天数',
      'currentCount': entryCount,
      'totalCount': totalDays,
      'items':
          sortedEntries.take(4).map((e) {
            final dateStr = DateFormat('MM月dd日').format(e.key);
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            final wordCount = e.value.content.length;
            return {
              'title': title,
              'subtitle': '$dateStr · $wordCount 字',
              'thumbnailUrl': null,
            };
          }).toList(),
    },

    // 每周点追踪卡片 - 显示本月每日打卡情况
    'monthlyDotTrackerCard': {
      'title': '本月日记打卡',
      'currentValue': entryCount,
      'totalDays': totalDays,
      'iconCodePoint': Icons.edit_calendar.codePoint,
      'daysData': List.generate(totalDays, (index) {
        final day = index + 1;
        final date = DateTime(year, month, day);
        final hasEntry = monthlyEntries.containsKey(date);
        return {'day': day, 'isChecked': hasEntry};
      }),
    },

    // 任务列表卡片 - 显示本月日记列表
    'taskListCard': {
      'title': '本月日记',
      'count': entryCount,
      'countLabel': '篇日记',
      'items':
          sortedEntries.take(8).map((e) {
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            return '$title (${DateFormat('MM月dd日').format(e.key)})';
          }).toList(),
      'moreCount': (entryCount - 8).clamp(0, 999),
    },

    // 月度进度圆点卡片 - 与 monthlyDotTrackerCard 类似
    'monthlyProgressDotsCard': {
      'title': '本月日记打卡',
      'currentValue': entryCount,
      'totalDays': totalDays,
      'iconCodePoint': Icons.edit_calendar.codePoint,
      'daysData': List.generate(totalDays, (index) {
        final day = index + 1;
        final date = DateTime(year, month, day);
        final hasEntry = monthlyEntries.containsKey(date);
        return {'day': day, 'isChecked': hasEntry};
      }),
    },

    // 消息列表卡片 - 显示日记摘要列表
    'messageListCard': {
      'featuredMessage': {
        'sender': '我的日记',
        'title':
            entryCount > 0
                ? '本月已记录 ${sortedEntries.first.value.content.length} 字'
                : '开始记录你的生活',
        'summary':
            entryCount > 0
                ? '本月共写了 $entryCount 篇日记，总计 $totalWordCount 字'
                : '点击开始写第一篇日记',
        'avatarUrl': '',
      },
      'messages':
          sortedEntries.take(5).map((e) {
            final dateStr = DateFormat('MM月dd日 EEEE', 'zh_CN').format(e.key);
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            final mood = e.value.mood ?? '';
            return {
              'title': '$mood $title',
              'sender': dateStr,
              'channel': '${e.value.content.length} 字',
              'avatarUrl': '',
            };
          }).toList(),
    },

    // 彩色标签任务卡片 - 按心情分类显示日记
    'colorTagTaskCard': {
      'taskCount': entryCount,
      'label': '本月日记',
      'tasks':
          sortedEntries.map((e) {
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            final dateStr = DateFormat('MM月dd日').format(e.key);
            final mood = e.value.mood ?? '😊';
            // 根据心情映射颜色
            int colorValue;
            switch (mood) {
              case '😊':
                colorValue = Colors.yellow.value;
                break;
              case '😢':
                colorValue = Colors.blue.value;
                break;
              case '😡':
                colorValue = Colors.red.value;
                break;
              default:
                colorValue = Colors.indigo.value;
            }
            return {
              'title': '($dateStr)',
              'color': colorValue,
              'tag': '$mood $title',
            };
          }).toList(),
      'moreCount': 0,
    },

    // 收件箱消息卡片
    'inboxMessageCard': {
      'title': '日记列表',
      'messages':
          sortedEntries.take(6).map((e) {
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            final dateStr = DateFormat('MM月dd日').format(e.key);
            final mood = e.value.mood ?? '';
            final preview =
                e.value.content.length > 50
                    ? '${e.value.content.substring(0, 50)}...'
                    : e.value.content;
            return {
              'title': title,
              'subtitle': '$dateStr ${mood.isNotEmpty ? '· $mood' : ''}',
              'content': preview,
              'time': dateStr,
              'isRead': true,
              'avatarUrl': null,
            };
          }).toList(),
      'unreadCount': 0,
    },

    // 即将到来的任务小组件 - 显示最近的日记
    'upcomingTasksWidget': {
      'title': '最近日记',
      'taskCount': entryCount.clamp(0, 4),
      'moreCount': (entryCount - 4).clamp(0, 999),
      'tasks':
          sortedEntries.take(4).map((e) {
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            final dateStr = DateFormat('MM月dd日').format(e.key);
            final mood = e.value.mood ?? '😊';
            int colorValue = Colors.indigo.value;
            if (mood == '😊') {
              colorValue = Colors.yellow.value;
            } else if (mood == '😢')
              colorValue = Colors.blue.value;
            else if (mood == '😡')
              colorValue = Colors.red.value;
            return {'title': title, 'color': colorValue, 'tag': dateStr};
          }).toList(),
    },

    // 圆角提醒事项列表 - 显示日记提醒
    'roundedRemindersList': {
      'title': '本月日记',
      'count': entryCount,
      'items':
          sortedEntries.take(5).map((e) {
            final title = e.value.title.isNotEmpty ? e.value.title : '无标题日记';
            final dateStr = DateFormat('MM月dd日').format(e.key);
            return {'text': '$dateStr - $title', 'isCompleted': true};
          }).toList(),
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
