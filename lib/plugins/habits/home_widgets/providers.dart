/// 习惯追踪插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import '../habits_plugin.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    if (plugin == null) return [];

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
      'color': Colors.amber.value,
    };
  }

  // 处理 Map 类型
  if (rawData is Map<String, dynamic>) {
    return {
      'id': rawData['id']?.toString(),
      'title': rawData['title']?.toString(),
      'group': rawData['group']?.toString(),
      'icon': rawData['icon']?.toString(),
      'color': Colors.amber.value,
    };
  }

  // 其他情况返回空 Map
  return {};
}
