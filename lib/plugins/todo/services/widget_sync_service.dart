import 'package:flutter/material.dart';
import '../../../core/services/system_widget_service.dart';
import '../../../core/plugin_manager.dart';
import '../todo_plugin.dart';

/// 待办事项插件的小组件数据同步服务
class TodoWidgetSyncService {
  static final TodoWidgetSyncService _instance = TodoWidgetSyncService._internal();
  factory TodoWidgetSyncService() => _instance;
  TodoWidgetSyncService._internal();

  static TodoWidgetSyncService get instance => _instance;

  /// 同步小组件数据
  Future<void> syncWidgetData() async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) return;

      final totalTasks = plugin.taskController.getTotalTaskCount();
      final weeklyTasks = plugin.taskController.getWeeklyTaskCount();
      final incompleteTasks = plugin.taskController.getIncompleteTaskCount();

      final widgetData = PluginWidgetData(
        pluginId: 'todo',
        pluginName: '待办事项',
        iconCodePoint: Icons.check_box.codePoint,
        colorValue: Colors.blue.value,
        stats: [
          WidgetStatItem(
            id: 'total_tasks',
            label: '总任务',
            value: '$totalTasks',
          ),
          WidgetStatItem(
            id: 'incomplete_tasks',
            label: '未完成',
            value: '$incompleteTasks',
            highlight: incompleteTasks > 0,
            colorValue: incompleteTasks > 0 ? Colors.orange.value : null,
          ),
        ],
      );

      await SystemWidgetService.instance.updateWidgetData('todo', widgetData);
    } catch (e) {
      debugPrint('TodoWidgetSyncService: Failed to sync widget data: $e');
    }
  }
}

/// 为其他插件提供的通用同步模板
///
/// 使用方法:
/// ```dart
/// // 在插件数据变更后调用
/// await TodoWidgetSyncService.instance.syncWidgetData();
///
/// // 或者在插件初始化时调用
/// @override
/// Future<void> initialize() async {
///   // ... 其他初始化代码
///   await TodoWidgetSyncService.instance.syncWidgetData();
/// }
/// ```
