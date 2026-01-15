import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/habit_streak_tracker.dart';

/// 习惯连续追踪卡片适配器
///
/// 包装 lib/widgets/common/habit_streak_tracker.dart 中的 HabitStreakTracker
/// 使其符合公共小组件系统的接口规范
class HabitStreakTrackerCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;
  final HomeWidgetSize size;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const HabitStreakTrackerCardWidget({
    super.key,
    required this.props,
    required this.size,
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory HabitStreakTrackerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return HabitStreakTrackerCardWidget(
      props: props,
      size: size,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String? ?? '习惯追踪';
    final currentStreak = props['currentStreak'] as int? ?? 0;
    final bestStreak = props['bestStreak'] as int? ?? 0;
    final totalCheckins = props['totalCheckins'] as int? ?? 0;

    // 从里程碑数据生成已完成天数列表
    final milestones = (props['milestones'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final completedDays = <int>[];
    for (final milestone in milestones) {
      if (milestone['isReached'] == true) {
        final days = milestone['days'] as int? ?? 0;
        completedDays.add(days);
      }
    }

    // 如果没有里程碑数据，使用当前连续天数
    if (completedDays.isEmpty && currentStreak > 0) {
      for (int i = 1; i <= currentStreak; i++) {
        completedDays.add(i);
      }
    }

    // 使用 totalCheckins 作为总天数（最多显示35天，7x5网格）
    final totalDays = (totalCheckins > 0 ? totalCheckins : currentStreak).clamp(1, 35);

    return HabitStreakTracker(
      currentStreak: currentStreak,
      longestStreak: bestStreak,
      totalDays: totalDays,
      completedDays: completedDays,
      titleText: title,
      longestStreakLabel: '最佳连续',
      padding: size.getPadding(),
    );
  }
}
