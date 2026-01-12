import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 睡眠追踪小组件示例
///
/// 展示 [WeeklySleepTrackerCard] 组件的使用方法
class WeeklySleepTrackerExample extends StatelessWidget {
  const WeeklySleepTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: WeeklySleepTrackerCard(
            totalHours: 3.57,
            statusLabel: 'Insomniac',
            weeklyData: [
              DaySleepData(isCompleted: true, progress: 1.0, day: 'M'),
              DaySleepData(isCompleted: false, progress: 0.68, day: 'T'),
              DaySleepData(isCompleted: true, progress: 1.0, day: 'W'),
              DaySleepData(isCompleted: true, progress: 0.92, day: 'T'),
              DaySleepData(isCompleted: false, progress: 0.60, day: 'F'),
              DaySleepData(isCompleted: false, progress: 0.76, day: 'S'),
              DaySleepData(isCompleted: true, progress: 1.0, day: 'S'),
            ],
          ),
        ),
      ),
    );
  }
}
