import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../habits_plugin.dart';
import '../models/habits_weekly_widget_data.dart';
import '../models/habit.dart';

/// 习惯周视图小组件业务逻辑服务
class HabitsWidgetService {
  final HabitsPlugin plugin;

  HabitsWidgetService(this.plugin);

  /// 计算指定周的数据
  Future<HabitsWeeklyData> calculateWeekData(
    List<String> habitIds,
    int weekOffset,
  ) async {
    // 1. 计算目标日期和周数
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: weekOffset * 7));
    final year = targetDate.year;
    final week = _calculateWeekOfYear(targetDate);

    // 2. 计算周起止日期
    final weekStart = _getWeekStart(year, week);
    final weekEnd = weekStart.add(const Duration(days: 6));

    // 3. 格式化周起止日期 (MM.DD)
    final dateFormat = DateFormat('MM.dd');
    final weekStartStr = dateFormat.format(weekStart);
    final weekEndStr = dateFormat.format(weekEnd);

    // 4. 获取所有习惯
    final allHabits = plugin.getHabitController().getHabits();

    // 5. 遍历选中的习惯ID,计算每个习惯的周数据
    final habitItems = <HabitWeeklyItem>[];
    for (final habitId in habitIds) {
      try {
        final habit = allHabits.firstWhere((h) => h.id == habitId);

        // 计算每日时长
        final dailyMinutes = await _calculateDailyMinutes(habitId, weekStart);

        // 获取习惯图标
        final habitIcon = _getHabitIcon(habit);

        // 获取习惯颜色
        final colorValue = _getHabitColor(habit);

        habitItems.add(
          HabitWeeklyItem(
            habitId: habit.id,
            habitTitle: habit.title,
            habitIcon: habitIcon,
            dailyMinutes: dailyMinutes,
            colorValue: colorValue,
          ),
        );
      } catch (e) {
        // 习惯不存在或已删除,跳过
        debugPrint('习惯 $habitId 不存在或已删除: $e');
        continue;
      }
    }

    return HabitsWeeklyData(
      year: year,
      week: week,
      weekStart: weekStartStr,
      weekEnd: weekEndStr,
      habitItems: habitItems,
    );
  }

  /// 计算某习惯在指定周的每日时长
  Future<List<int>> _calculateDailyMinutes(
    String habitId,
    DateTime weekStart,
  ) async {
    List<int> dailyMinutes = List.filled(7, 0);

    try {
      // 获取习惯的完成记录
      final recordController = plugin.getRecordController();
      final records = await recordController.getHabitCompletionRecords(habitId);

      // 遍历7天
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dayStart = weekStart.add(Duration(days: dayIndex));
        final dayEnd = dayStart.add(const Duration(days: 1));

        // 筛选当天的记录并聚合时长
        int totalMinutes = 0;
        for (final record in records) {
          if (record.date.isAfter(dayStart) && record.date.isBefore(dayEnd)) {
            totalMinutes = totalMinutes + (record.duration.inMinutes as int);
          }
        }

        dailyMinutes[dayIndex] = totalMinutes;
      }
    } catch (e) {
      debugPrint('计算习惯 $habitId 每日时长失败: $e');
    }

    return dailyMinutes;
  }

  /// ISO 8601周数计算
  /// 规则: 第1周包含1月4日,周一为起始日
  int _calculateWeekOfYear(DateTime date) {
    // 找到包含1月4日的那一周的周一
    final firstDayOfYear = DateTime(date.year, 1, 4);
    final daysFromMonday = (firstDayOfYear.weekday - 1) % 7;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysFromMonday));

    // 计算目标日期距离第一周周一的天数
    final daysSinceFirstMonday = date.difference(firstMonday).inDays;

    // 计算周数 (至少为第1周)
    return max(1, (daysSinceFirstMonday / 7).floor() + 1);
  }

  /// 获取指定年份和周数的周一日期
  DateTime _getWeekStart(int year, int week) {
    // 找到包含1月4日的那一周的周一
    final firstDayOfYear = DateTime(year, 1, 4);
    final daysFromMonday = (firstDayOfYear.weekday - 1) % 7;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysFromMonday));

    // 加上偏移周数
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

  /// 获取习惯图标
  /// 优先返回emoji,如果没有则返回MaterialIcons codePoint
  String _getHabitIcon(Habit habit) {
    // 如果习惯有图标代码(MaterialIcons codePoint)
    if (habit.icon != null && habit.icon!.isNotEmpty) {
      try {
        // 尝试解析为codePoint
        final codePoint = int.parse(habit.icon!);
        // 转换为字符(emoji或Unicode字符)
        return String.fromCharCode(codePoint);
      } catch (e) {
        // 解析失败,可能直接就是emoji
        return habit.icon!;
      }
    }

    // 如果没有图标,返回默认emoji
    return '⏰';
  }

  /// 获取习惯颜色
  /// 参考TimerDialog._getColor()逻辑
  int _getHabitColor(Habit habit) {
    // 预定义颜色数组(与TimerDialog保持一致)
    final colors = [
      0xFF607AFB, // Blue
      0xFFFF6B6B, // Red
      0xFF4ECDC4, // Teal
      0xFF9D81E8, // Purple
      0xFFFFD93D, // Yellow
      0xFFFF8D29, // Orange
    ];

    // 使用习惯ID或关联的技能ID哈希选择颜色
    final id = habit.skillId ?? habit.id;
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }
}
