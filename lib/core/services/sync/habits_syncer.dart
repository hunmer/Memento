import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../plugins/habits/habits_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';
import '../system_widget_service.dart';

/// 习惯插件同步器
class HabitsSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for habits');
      return;
    }

    await syncSafely('habits', () async {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) return;

      final habitCount = plugin.getHabitController().getHabits().length;
      final skillCount = plugin.getSkillController().getSkills().length;

      await updateWidget(
        pluginId: 'habits',
        pluginName: '习惯',
        iconCodePoint: Icons.auto_awesome.codePoint,
        colorValue: Colors.amber.value,
        stats: [
          WidgetStatItem(id: 'habits', label: '习惯', value: '$habitCount'),
          WidgetStatItem(id: 'skills', label: '技能', value: '$skillCount'),
        ],
      );
    });
  }

  /// 同步习惯计时器小组件
  Future<void> syncHabitTimerWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) {
        debugPrint('Habits plugin not found, skipping habit_timer widget sync');
        return;
      }

      // 获取所有习惯
      final habits = plugin.getHabitController().getHabits();

      // 构建习惯数据（包含所有习惯，供Android端查找）
      final habitsData = habits.map((habit) {
        // 获取计时器状态
        final timerData = plugin.timerController.getTimerData(habit.id);
        final isRunning = plugin.timerController.isHabitTiming(habit.id);

        return {
          'id': habit.id,
          'title': habit.title,
          'durationMinutes': habit.durationMinutes,
          'icon': habit.icon,
          'isRunning': isRunning,
          'elapsedSeconds': timerData?['elapsedSeconds'] ?? 0,
          'isCountdown': timerData?['isCountdown'] ?? true,
        };
      }).toList();

      // 保存为 JSON 字符串
      await MyWidgetManager().saveString(
        'habit_timer_widget_data',
        jsonEncode({'habits': habitsData}),
      );

      // 更新小组件
      await SystemWidgetService.instance.updateWidget('habit_timer');

      debugPrint('Synced habit_timer widget with ${habits.length} habits');
    } catch (e) {
      debugPrint('Failed to sync habit_timer widget: $e');
    }
  }

  // 防止重复同步的标志
  bool _isSyncingPendingTimerChanges = false;

  /// 应用启动或恢复时同步待处理的习惯计时器变更
  /// 在 main.dart 中调用，确保用户在小组件上启动/暂停的计时器能立即同步到应用
  Future<void> syncPendingHabitTimerChangesOnStartup() async {
    try {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) {
        debugPrint('Habits plugin not found, skipping pending timer changes sync');
        return;
      }

      await _syncPendingHabitTimerChanges(plugin);
    } catch (e) {
      debugPrint('Failed to sync pending habit timer changes on startup: $e');
    }
  }

  /// 同步待处理的习惯计时器变更（从小组件后台启动/暂停的计时器）
  Future<void> _syncPendingHabitTimerChanges(HabitsPlugin plugin) async {
    if (_isSyncingPendingTimerChanges) {
      debugPrint('Already syncing pending timer changes, skipping');
      return;
    }

    try {
      final pendingJson = await MyWidgetManager().getData<String>('habit_timer_pending_changes');
      if (pendingJson == null || pendingJson.isEmpty || pendingJson == '{}') {
        return;
      }

      debugPrint('Found pending habit timer changes: $pendingJson');

      final pending = jsonDecode(pendingJson) as Map<String, dynamic>;
      if (pending.isEmpty) return;

      // 先清除待处理的变更
      await MyWidgetManager().saveString('habit_timer_pending_changes', '{}');
      debugPrint('Cleared pending habit timer changes');

      _isSyncingPendingTimerChanges = true;

      // 处理每个变更
      for (final entry in pending.entries) {
        final habitId = entry.key;
        final change = entry.value as Map<String, dynamic>;
        final isRunning = change['isRunning'] as bool;

        debugPrint('Syncing pending timer change: habitId=$habitId, running=$isRunning');

        try {
          // 查找习惯
          final habit = plugin.getHabitController().getHabits().firstWhere(
            (h) => h.id == habitId,
            orElse: () => throw ArgumentError('Habit not found: $habitId'),
          );

          // 启动或暂停计时器
          if (isRunning) {
            // 启动计时器
            plugin.timerController.startTimer(habit, (_) {
              // 更新回调（可选）
            });
            debugPrint('Started timer for habit: ${habit.title}');
          } else {
            // 暂停计时器
            plugin.timerController.pauseTimer(habitId);
            debugPrint('Paused timer for habit: ${habit.title}');
          }
        } catch (e) {
          debugPrint('Failed to sync timer for habit $habitId: $e');
        }
      }

      // 同步完成后更新小组件
      await syncHabitTimerWidget();
    } catch (e) {
      debugPrint('Failed to sync pending timer changes: $e');
    } finally {
      _isSyncingPendingTimerChanges = false;
    }
  }
}
