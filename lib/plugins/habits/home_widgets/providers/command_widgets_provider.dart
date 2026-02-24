/// 习惯追踪插件 - 公共小组件数据提供者
library;

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

/// 提供公共小组件的数据
class HabitsCommandWidgetsProvider {
  /// 获取公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> config,
  ) async {
    final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    if (plugin == null) return {};

    final habitController = plugin.getHabitController();
    final recordController = plugin.getRecordController();
    final timerController = plugin.timerController;

    // 从 config 中提取 habitId
    String? habitId;
    if (config.containsKey('data')) {
      final dataList = config['data'];
      if (dataList is List && dataList.isNotEmpty) {
        final firstItem = dataList[0];
        if (firstItem is Map<String, dynamic>) {
          habitId = firstItem['habitId']?.toString() ?? firstItem['id']?.toString();
        }
      }
    }

    if (habitId == null || habitId.isEmpty) {
      return {};
    }

    final habits = habitController.getHabits();
    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found: $habitId'),
    );

    // 获取统计数据
    final completionCount = await recordController.getCompletionCount(habitId);
    final totalDurationMinutes = await recordController.getTotalDuration(habitId);
    final todayRecords = (await recordController.getHabitCompletionRecords(habitId))
        .where((r) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day;
        }).toList();

    // 获取过去7天的状态
    final now = DateTime.now();
    final last7DaysStatus = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      return todayRecords.any((r) {
        return r.date.isAfter(dateStart.subtract(const Duration(seconds: 1))) &&
            r.date.isBefore(dateEnd);
      });
    });

    // 获取计时器状态
    final isTiming = timerController.isHabitTiming(habitId);
    final timerData = timerController.getTimerData(habitId);
    String timerText = '00:00';
    if (timerData != null) {
      final elapsed = timerData['elapsedSeconds'] as int? ?? 0;
      timerText = _formatDuration(elapsed);
    }

    // 获取技能标题
    String? skillTitle;
    if (habit.skillId != null) {
      try {
        final skill = plugin.getSkillController().getSkillById(habit.skillId!);
        skillTitle = skill?.title;
      } catch (_) {}
    }

    // 生成主题色
    final habitColor = HabitsUtils.generateColorForHabit(habit);

    return {
      'habitCard': {
        'data': {
          'id': habit.id,
          'title': habit.title,
          'icon': habit.icon,
          'skillTitle': skillTitle ?? habit.group,
          'group': habit.group,
          'themeColor': habitColor.value,
          'completionCount': completionCount,
          'todayCount': todayRecords.length,
          'totalDurationMinutes': totalDurationMinutes,
          'last7DaysStatus': last7DaysStatus,
          'durationMinutes': habit.durationMinutes,
          'currentTotalDurationMinutes': habit.totalDurationMinutes,
          'isTiming': isTiming,
          'timerText': timerText,
        },
      },
    };
  }

  /// 格式化时长（秒 -> 分:秒）
  static String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
