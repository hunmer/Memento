import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';
import 'package:Memento/core/services/system_widget_service.dart';

/// 目标追踪插件同步器
class TrackerSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('tracker', () async {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) return;

      final totalGoals = plugin.getGoalCount();
      final activeGoals = plugin.getActiveGoalCount();
      final todayRecords = plugin.getTodayRecordCount();

      await updateWidget(
        pluginId: 'tracker',
        pluginName: '目标',
        iconCodePoint: Icons.track_changes.codePoint,
        colorValue: Colors.orange.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总目标数', value: '$totalGoals'),
          WidgetStatItem(
            id: 'active',
            label: '进行中',
            value: '$activeGoals',
            highlight: activeGoals > 0,
            colorValue: activeGoals > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'records',
            label: '今日记录',
            value: '$todayRecords',
            highlight: todayRecords > 0,
            colorValue: todayRecords > 0 ? Colors.green.value : null,
          ),
        ],
      );
    });
  }

  /// 同步目标进度自定义小组件
  Future<void> syncTrackerGoalWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) {
        debugPrint('Tracker plugin not found, skipping tracker_goal widget sync');
        return;
      }

      // 获取所有目标
      final goals = plugin.controller.goals;

      // 构建目标列表数据
      final items = goals.map((goal) {
        return {
          'id': goal.id,
          'name': goal.name,
          'currentValue': goal.currentValue,
          'targetValue': goal.targetValue,
          'unitType': goal.unitType,
          'isCompleted': goal.isCompleted,
        };
      }).toList();

      // 保存为 JSON 格式到 SharedPreferences
      final data = {'goals': items, 'total': items.length};
      final jsonString = jsonEncode(data);
      await MyWidgetManager().saveString('tracker_goal_widget_data', jsonString);

      // 更新目标进度小组件
      await SystemWidgetService.instance.updateWidget('tracker_goal');

      debugPrint('Synced tracker_goal widget with ${items.length} goals');
    } catch (e) {
      debugPrint('Failed to sync tracker_goal widget: $e');
    }
  }

  // 防止重复同步的标志
  bool _isSyncingPendingChanges = false;

  /// 应用启动或恢复时同步待处理的目标变更
  /// 在 main.dart 中调用，确保用户在小组件上增减的进度能立即同步到应用
  Future<void> syncPendingGoalChangesOnStartup() async {
    try {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) {
        debugPrint('Tracker plugin not found, skipping pending changes sync');
        return;
      }

      await _syncPendingGoalChanges(plugin);
    } catch (e) {
      debugPrint('Failed to sync pending goal changes on startup: $e');
    }
  }

  /// 同步待处理的目标变更（从小组件后台增减的进度）
  Future<void> _syncPendingGoalChanges(TrackerPlugin plugin) async {
    if (_isSyncingPendingChanges) {
      debugPrint('Already syncing pending goal changes, skipping');
      return;
    }

    try {
      final pendingJson = await MyWidgetManager().getData<String>('tracker_goal_pending_changes');
      if (pendingJson == null || pendingJson.isEmpty || pendingJson == '{}') {
        return;
      }

      debugPrint('Found pending goal changes: $pendingJson');

      final pending = jsonDecode(pendingJson) as Map<String, dynamic>;
      if (pending.isEmpty) return;

      // 先清除待处理的变更
      await MyWidgetManager().saveString('tracker_goal_pending_changes', '{}');
      debugPrint('Cleared pending goal changes');

      _isSyncingPendingChanges = true;

      // 处理每个变更
      for (final entry in pending.entries) {
        final goalId = entry.key;
        final delta = (entry.value as num).toDouble();

        debugPrint('Syncing pending change: goalId=$goalId, delta=$delta');

        try {
          // 查找目标
          final goal = plugin.controller.goals.firstWhere(
            (g) => g.id == goalId,
            orElse: () => throw ArgumentError('Goal not found: $goalId'),
          );

          // 通过添加记录来更新目标值
          if (delta != 0) {
            final record = Record(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              goalId: goalId,
              value: delta,
              note: '小组件快捷操作',
              recordedAt: DateTime.now(),
            );
            await plugin.controller.addRecord(record, goal);
            debugPrint('Added record for goal $goalId: delta=$delta');
          }
        } catch (e) {
          debugPrint('Failed to sync goal $goalId: $e');
        }
      }

      // 同步小组件数据
      await syncTrackerGoalWidget();

      debugPrint('All pending goal changes synced');
    } catch (e) {
      debugPrint('Failed to sync pending goal changes: $e');
    } finally {
      _isSyncingPendingChanges = false;
    }
  }
}
