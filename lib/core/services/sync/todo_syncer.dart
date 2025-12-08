import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:memento_widgets/memento_widgets.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:Memento/core/services/system_widget_service.dart';

/// 待办事项插件同步器
class TodoSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('todo', () async {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) return;

      final totalTasks = plugin.taskController.getTotalTaskCount();
      final incompleteTasks = plugin.taskController.getIncompleteTaskCount();

      await updateWidget(
        pluginId: 'todo',
        pluginName: '待办事项',
        iconCodePoint: Icons.check_box.codePoint,
        colorValue: Colors.blue.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总任务', value: '$totalTasks'),
          WidgetStatItem(
            id: 'incomplete',
            label: '未完成',
            value: '$incompleteTasks',
            highlight: incompleteTasks > 0,
            colorValue: incompleteTasks > 0 ? Colors.orange.value : null,
          ),
        ],
      );
    });
  }

  /// 同步待办列表自定义小组件
  Future<void> syncTodoListWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) {
        debugPrint('Todo plugin not found, skipping todo_list widget sync');
        return;
      }

      // 获取所有未完成任务
      final allTasks = plugin.taskController.tasks
          .where((task) => task.status != TaskStatus.done)
          .toList();

      // 构建任务列表数据（只包含基本信息）
      final items = allTasks.map((task) {
        return {
          'id': task.id,
          'title': task.title,
          'completed': task.status == TaskStatus.done,
          'startDate': task.startDate?.toIso8601String(),
          'dueDate': task.dueDate?.toIso8601String(),
        };
      }).toList();

      // 保存为 JSON 格式到 SharedPreferences
      final data = {'tasks': items, 'total': items.length};
      final jsonString = jsonEncode(data);
      await MyWidgetManager().saveString('todo_list_widget_data', jsonString);

      // 更新待办列表小组件
      await SystemWidgetService.instance.updateWidget('todo_list');

      debugPrint('Synced todo_list widget with ${items.length} tasks');
    } catch (e) {
      debugPrint('Failed to sync todo_list widget: $e');
    }
  }

  /// 应用启动时同步待处理的小组件任务变更
  Future<void> syncPendingTaskChangesOnStartup() async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) {
        debugPrint('Todo plugin not found, skipping pending changes sync');
        return;
      }

      await _syncPendingTaskChanges(plugin);
    } catch (e) {
      debugPrint('Failed to sync pending task changes on startup: $e');
    }
  }

  // 防止重复同步的标志
  bool _isSyncingPendingChanges = false;

  /// 同步待处理的任务变更（从小组件后台完成的任务）
  Future<void> _syncPendingTaskChanges(TodoPlugin plugin) async {
    if (_isSyncingPendingChanges) {
      debugPrint('Already syncing pending changes, skipping');
      return;
    }

    try {
      final pendingJson = await MyWidgetManager().getData<String>('todo_list_pending_changes');
      if (pendingJson == null || pendingJson.isEmpty || pendingJson == '{}') {
        return;
      }

      debugPrint('Found pending task changes: $pendingJson');

      final pending = jsonDecode(pendingJson) as Map<String, dynamic>;
      if (pending.isEmpty) return;

      // 先清除待处理的变更
      await MyWidgetManager().saveString('todo_list_pending_changes', '{}');
      debugPrint('Cleared pending task changes');

      _isSyncingPendingChanges = true;

      // 处理每个变更
      for (final entry in pending.entries) {
        final taskId = entry.key;
        final completed = entry.value as bool;

        debugPrint('Syncing pending change: taskId=$taskId, completed=$completed');

        try {
          if (completed) {
            await plugin.taskController.updateTaskStatus(taskId, TaskStatus.done);
          } else {
            await plugin.taskController.updateTaskStatus(taskId, TaskStatus.todo);
          }
        } catch (e) {
          debugPrint('Failed to sync task $taskId: $e');
        }
      }

      debugPrint('All pending task changes synced');
    } catch (e) {
      debugPrint('Failed to sync pending task changes: $e');
    } finally {
      _isSyncingPendingChanges = false;
    }
  }

  /// 同步四象限任务自定义小组件
  Future<void> syncTodoQuadrantWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) {
        debugPrint('Todo plugin not found, skipping todo_quadrant widget sync');
        return;
      }

      // 获取所有未完成任务
      final allTasks = plugin.taskController.tasks
          .where((task) => task.status != TaskStatus.done)
          .toList();

      // 按优先级和紧急程度分组到四个象限
      final now = DateTime.now();
      final urgentImportantTasks = <Map<String, dynamic>>[];
      final notUrgentImportantTasks = <Map<String, dynamic>>[];
      final urgentNotImportantTasks = <Map<String, dynamic>>[];
      final notUrgentNotImportantTasks = <Map<String, dynamic>>[];

      for (final task in allTasks) {
        final bool isImportant = task.priority == TaskPriority.high || task.priority == TaskPriority.medium;
        final bool isUrgent = task.dueDate != null &&
            (task.dueDate!.isBefore(now.add(Duration(days: 2))) ||
             task.dueDate!.isAtSameMomentAs(DateTime(now.year, now.month, now.day)));

        final taskData = {
          'id': task.id,
          'title': task.title,
          'priority': task.priority.index,
          'dueDate': task.dueDate?.toIso8601String(),
        };

        if (isImportant && isUrgent) {
          urgentImportantTasks.add(taskData);
        } else if (isImportant && !isUrgent) {
          notUrgentImportantTasks.add(taskData);
        } else if (!isImportant && isUrgent) {
          urgentNotImportantTasks.add(taskData);
        } else {
          notUrgentNotImportantTasks.add(taskData);
        }
      }

      // 构建四象限数据
      final quadrantData = {
        'urgent_important': urgentImportantTasks,
        'not_urgent_important': notUrgentImportantTasks,
        'urgent_not_important': urgentNotImportantTasks,
        'not_urgent_not_important': notUrgentNotImportantTasks,
        'total_count': allTasks.length,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 保存为 JSON 格式
      final jsonString = jsonEncode(quadrantData);
      await MyWidgetManager().saveString('todo_quadrant_widget_data', jsonString);

      // 更新小组件
      await SystemWidgetService.instance.updateWidget('todo_quadrant');

      debugPrint('Synced todo_quadrant widget with ${allTasks.length} tasks');
    } catch (e) {
      debugPrint('Failed to sync todo_quadrant widget: $e');
    }
  }

  /// 应用启动时同步待处理的四象限任务变更
  Future<void> syncPendingQuadrantChangesOnStartup() async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) {
        debugPrint('Todo plugin not found, skipping pending quadrant changes sync');
        return;
      }

      await _syncPendingQuadrantChanges(plugin);
    } catch (e) {
      debugPrint('Failed to sync pending quadrant changes on startup: $e');
    }
  }

  /// 同步待处理的任务变更（四象限小组件）
  Future<void> _syncPendingQuadrantChanges(TodoPlugin plugin) async {
    try {
      final pendingJson = await MyWidgetManager().getData<String>('todo_quadrant_pending_changes');
      if (pendingJson == null || pendingJson.isEmpty || pendingJson == '{}') {
        return;
      }

      debugPrint('Found pending quadrant changes: $pendingJson');

      final pending = jsonDecode(pendingJson) as Map<String, dynamic>;
      if (pending.isEmpty) return;

      // 清除待处理的变更
      await MyWidgetManager().saveString('todo_quadrant_pending_changes', '{}');

      // 处理每个变更
      for (final entry in pending.entries) {
        final taskId = entry.key;
        final completed = entry.value as bool;

        debugPrint('Syncing quadrant pending change: taskId=$taskId, completed=$completed');

        try {
          if (completed) {
            await plugin.taskController.updateTaskStatus(taskId, TaskStatus.done);
          } else {
            await plugin.taskController.updateTaskStatus(taskId, TaskStatus.todo);
          }
        } catch (e) {
          debugPrint('Failed to sync task $taskId: $e');
        }
      }

      debugPrint('All pending quadrant changes synced');
    } catch (e) {
      debugPrint('Failed to sync pending quadrant changes: $e');
    }
  }
}
