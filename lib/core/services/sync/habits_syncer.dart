import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:uuid/uuid.dart';
import '../../../plugins/habits/habits_plugin.dart';
import '../../../plugins/habits/models/completion_record.dart';
import '../../../plugins/habits/services/habits_widget_service.dart';
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

        // 检查是否为完成事件
        if (change.containsKey('action') && change['action'] == 'complete') {
          // 处理完成事件
          final elapsedSeconds = change['elapsedSeconds'] as int;
          debugPrint('Syncing pending completion: habitId=$habitId, elapsed=$elapsedSeconds');

          try {
            // 查找习惯
            final habit = plugin.getHabitController().getHabits().firstWhere(
              (h) => h.id == habitId,
              orElse: () => throw ArgumentError('Habit not found: $habitId'),
            );

            // 创建完成记录
            final record = CompletionRecord(
              id: const Uuid().v4(),
              parentId: habitId,
              date: DateTime.now(),
              duration: Duration(seconds: elapsedSeconds),
              notes: '从小组件完成',
            );

            // 保存完成记录
            await plugin.getRecordController().saveCompletionRecord(habitId, record);
            debugPrint('Completed timer for habit: ${habit.title}, duration: ${elapsedSeconds}s');

            // 清除计时器状态（如果存在）
            plugin.timerController.clearTimerData(habitId);
          } catch (e) {
            debugPrint('Failed to complete timer for habit $habitId: $e');
          }
        } else {
          // 处理启动/暂停事件
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
      }

      // 同步完成后更新小组件
      await syncHabitTimerWidget();
    } catch (e) {
      debugPrint('Failed to sync pending timer changes: $e');
    } finally {
      _isSyncingPendingTimerChanges = false;
    }
  }

  /// 同步习惯周视图小组件
  ///
  /// 遍历所有已配置的周视图小组件,更新其数据
  Future<void> syncHabitsWeeklyWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) {
        debugPrint('Habits plugin not found, skipping weekly widget sync');
        return;
      }

      // 获取所有已配置的小组件ID列表
      final widgetIdsJson = await HomeWidget.getWidgetData<String>(
        'habits_weekly_widget_ids',
      );

      if (widgetIdsJson == null || widgetIdsJson.isEmpty) {
        debugPrint('No configured habits weekly widgets found');
        return;
      }

      final widgetIds = List<int>.from(jsonDecode(widgetIdsJson) as List);

      final widgetService = HabitsWidgetService(plugin);

      // 同步每个小组件
      for (final widgetId in widgetIds) {
        try {
          await _syncSingleWeeklyWidget(widgetId, widgetService);
        } catch (e) {
          debugPrint('Failed to sync habits weekly widget $widgetId: $e');
        }
      }

      // 通知系统刷新所有习惯周视图小组件
      await SystemWidgetService.instance.updateWidget('habits_weekly');

      debugPrint('Synced ${widgetIds.length} habits weekly widgets');
    } catch (e) {
      debugPrint('Failed to sync habits weekly widgets: $e');
    }
  }

  /// 同步习惯分组列表小组件
  ///
  /// 同步所有习惯和技能数据到习惯分组列表小组件
  Future<void> syncHabitGroupListWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) {
        debugPrint('Habits plugin not found, skipping habit_group_list widget sync');
        return;
      }

      final habits = plugin.getHabitController().getHabits();
      final skills = plugin.getSkillController().getSkills();

      // 构建分组数据
      final groupsData = skills.map((skill) {
        return {
          'id': skill.id,
          'name': skill.title,
          'icon': skill.icon ?? '📂',
        };
      }).toList();

      // 构建习惯数据
      final habitsData = habits.map((habit) {
        return {
          'id': habit.id,
          'title': habit.title,
          'icon': habit.icon,
          'group': habit.skillId,
          'completed': false, // TODO: 从完成记录中获取今日完成状态
        };
      }).toList();

      // 保存为 JSON 字符串
      await MyWidgetManager().saveString(
        'habit_group_list_widget_data',
        jsonEncode({
          'groups': groupsData,
          'habits': habitsData,
        }),
      );

      // 更新小组件
      await SystemWidgetService.instance.updateWidget('habit_group_list');

      debugPrint('Synced habit_group_list widget with ${habits.length} habits and ${skills.length} groups');
    } catch (e) {
      debugPrint('Failed to sync habit_group_list widget: $e');
    }
  }

  /// 同步单个周视图小组件
  Future<void> _syncSingleWeeklyWidget(
    int widgetId,
    HabitsWidgetService widgetService,
  ) async {
    // 读取小组件配置
    final widgetDataJson = await HomeWidget.getWidgetData<String>(
      'habits_weekly_data_$widgetId',
    );

    List<String> selectedHabitIds = [];
    int weekOffset = 0;

    if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
      try {
        final widgetData = jsonDecode(widgetDataJson) as Map<String, dynamic>;
        final configJson = widgetData['config'] as Map<String, dynamic>?;
        if (configJson != null) {
          selectedHabitIds = List<String>.from(configJson['selectedHabitIds'] as List);
          weekOffset = configJson['weekOffset'] as int? ?? 0;
        }
      } catch (e) {
        debugPrint('Failed to parse widget config for $widgetId: $e');
        return;
      }
    }

    if (selectedHabitIds.isEmpty) {
      debugPrint('No habits selected for widget $widgetId, skipping sync');
      return;
    }

    // 计算周数据
    final weekData = await widgetService.calculateWeekData(
      selectedHabitIds,
      weekOffset,
    );

    // 更新数据(保留现有配置,只更新数据部分)
    if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
      try {
        final widgetData = jsonDecode(widgetDataJson) as Map<String, dynamic>;
        widgetData['data'] = weekData.toMap();

        // 打印详细的周数据用于调试
        debugPrint('=== 习惯周视图数据 (widgetId=$widgetId) ===');
        debugPrint('年: ${weekData.year}, 周: ${weekData.week}');
        debugPrint('周起止: ${weekData.weekStart} - ${weekData.weekEnd}');
        for (final item in weekData.habitItems) {
          debugPrint('习惯: ${item.habitTitle}, dailyMinutes: ${item.dailyMinutes}');
        }
        debugPrint('===========================================');

        final jsonStr = jsonEncode(widgetData);

        await HomeWidget.saveWidgetData<String>(
          'habits_weekly_data_$widgetId',
          jsonStr,
        );

        // 添加短暂延迟确保数据已写入 SharedPreferences
        await Future.delayed(const Duration(milliseconds: 50));

        debugPrint('Updated habits weekly widget $widgetId data');
      } catch (e) {
        debugPrint('Failed to update widget $widgetId data: $e');
      }
    }
  }
}
