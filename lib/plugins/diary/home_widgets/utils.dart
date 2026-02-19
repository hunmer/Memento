/// 日记插件主页小组件工具函数
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../diary_plugin.dart';
import '../screens/diary_editor_screen.dart';
import '../utils/diary_utils.dart';

/// 获取当前周的周一到周日日期列表
///
/// 返回从本周一到周日的7个日期对象
List<DateTime> getCurrentWeekDays(DateTime date) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  // Monday = 1, Sunday = 7
  final weekday = normalizedDate.weekday;
  // 计算周一
  final monday = normalizedDate.subtract(Duration(days: weekday - 1));
  // 生成周一到周日的日期列表
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}

/// 打开日记编辑器
///
/// 导航到指定日期的日记编辑页面，如果存在日记则加载现有内容
Future<void> openDiaryEditor(
  BuildContext context,
  DateTime date,
) async {
  final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
  if (plugin == null) return;

  // 加载现有日记（如果存在）
  final entry = await DiaryUtils.loadDiaryEntry(date);

  NavigationHelper.push(
    context,
    DiaryEditorScreen(
      date: date,
      storage: plugin.storage,
      initialTitle: entry?.title ?? '',
      initialContent: entry?.content ?? '',
    ),
  );
}

/// 获取可用的统计项数据
///
/// 用于概览小组件的统计信息展示
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
    if (plugin == null) return [];

    // 同步获取统计数据
    final todayCount = plugin.getTodayWordCountSync();
    final monthCount = plugin.getMonthWordCountSync();
    final monthProgress = plugin.getMonthProgressSync();

    return [
      StatItemData(
        id: 'today_word_count',
        label: '今日字数',
        value: '$todayCount',
        highlight: todayCount > 0,
        color: Colors.indigo,
      ),
      StatItemData(
        id: 'month_word_count',
        label: '本月字数',
        value: '$monthCount',
        highlight: false,
      ),
      StatItemData(
        id: 'month_progress',
        label: '本月进度',
        value: '${monthProgress.$1}/${monthProgress.$2}',
        highlight: monthProgress.$1 > 0,
        color: Colors.indigo,
      ),
    ];
  } catch (e) {
    return [];
  }
}
