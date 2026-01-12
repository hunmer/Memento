import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 每周步数进度卡片示例
class WeeklyStepsProgressCardExample extends StatelessWidget {
  const WeeklyStepsProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每周步数进度卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E5E5),
        child: const Center(
          child: WeeklyStepsProgressCard(
            title: 'Steps',
            totalSteps: 16254,
            dateRange: '17-23 Jun 2024',
            averageSteps: 6028,
            dailyData: [
              DailyStepData(
                day: 'Mon',
                steps: 4500,
                date: '17 Jun 2024',
              ),
              DailyStepData(
                day: 'Tue',
                steps: 6200,
                date: '18 Jun 2024',
              ),
              DailyStepData(
                day: 'Wed',
                steps: 3800,
                date: '19 Jun 2024',
              ),
              DailyStepData(
                day: 'Thu',
                steps: 7800,
                date: '20 Jun 2024',
              ),
              DailyStepData(
                day: 'Fri',
                steps: 12800,
                date: '21 Jun 2024',
                percentage: '+2,4%',
                isSelected: true,
              ),
              DailyStepData(
                day: 'Sat',
                steps: 9600,
                date: '22 Jun 2024',
              ),
              DailyStepData(
                day: 'Sun',
                steps: 7200,
                date: '23 Jun 2024',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
