import 'package:Memento/widgets/common/index.dart';
import 'package:flutter/material.dart';

/// 连续打卡追踪器示例
class HabitStreakTrackerExample extends StatelessWidget {
  const HabitStreakTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('连续打卡追踪器')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
        child: const Center(
          child: HabitStreakTracker(
            currentStreak: 5,
            longestStreak: 15,
            totalDays: 10,
            completedDays: [1, 2, 3, 4, 5],
          ),
        ),
      ),
    );
  }
}
