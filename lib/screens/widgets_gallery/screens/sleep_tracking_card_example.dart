import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 睡眠追踪卡片示例
class SleepTrackingCardExample extends StatelessWidget {
  const SleepTrackingCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SleepTrackingCard(
            sleepHours: 3.57,
            sleepLabel: 'Insomniac',
            weeklyProgress: [
              WeekSleepData(day: 'M', achieved: true, progress: 1.0),
              WeekSleepData(day: 'T', achieved: false, progress: 0.68),
              WeekSleepData(day: 'W', achieved: true, progress: 1.0),
              WeekSleepData(day: 'T', achieved: true, progress: 0.92),
              WeekSleepData(day: 'F', achieved: false, progress: 0.6),
              WeekSleepData(day: 'S', achieved: false, progress: 0.76),
              WeekSleepData(day: 'S', achieved: true, progress: 1.0),
            ],
          ),
        ),
      ),
    );
  }
}
