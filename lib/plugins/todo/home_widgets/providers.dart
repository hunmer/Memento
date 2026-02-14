/// 待办插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/models/task.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
    if (plugin == null) return [];

    final totalTasks = plugin.taskController.getTotalTaskCount();
    final weeklyTasks = plugin.taskController.getWeeklyTaskCount();

    return [
      StatItemData(
        id: 'total_tasks',
        label: 'todo_totalTasks'.tr,
        value: '$totalTasks',
        highlight: false,
      ),
      StatItemData(
        id: 'weekly_tasks',
        label: 'todo_weeklyTasks'.tr,
        value: '$weeklyTasks',
        highlight: weeklyTasks > 0,
        color: Colors.orange,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 获取待办任务列表（简略信息）
List<Map<String, dynamic>> getTodoTasks(int limit) {
  try {
    final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
    if (plugin != null) {
      final controller = plugin.taskController;
      final tasks = controller.tasks;
      // 获取未完成的任务，按优先级排序
      final pendingTasks = tasks
          .where((t) => t.status != TaskStatus.done)
          .toList()
        ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
      return pendingTasks.take(limit).map((task) {
        return {
          'id': task.id,
          'title': task.title,
          'priority': task.priority.index,
          'status': task.status.index,
        };
      }).toList();
    }
  } catch (e) {
    debugPrint('[TodoHomeWidgets] 获取任务列表失败: $e');
  }
  return [];
}
