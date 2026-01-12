import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/sleep_stage_chart_card.dart';

/// 睡眠阶段图表示例
class SleepStageChartExample extends StatelessWidget {
  const SleepStageChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠阶段图表')),
      body: Container(
        color: isDark ? const Color(0xFFEBB305) : const Color(0xFFFDFDFD),
        child: const Center(
          child: SleepStageChartCard(
            sleepStages: [
              SleepStageData(
                type: SleepStageType.core,
                left: 0,
                topPercent: 20,
                widthPercent: 55,
                height: 48,
              ),
              SleepStageData(
                type: SleepStageType.postREM,
                left: 30,
                topPercent: 65,
                widthPercent: 10,
                height: 40,
              ),
              SleepStageData(
                type: SleepStageType.rem,
                left: 45,
                topPercent: 45,
                widthPercent: 38,
                height: 48,
              ),
              SleepStageData(
                type: SleepStageType.deep,
                left: 80,
                topPercent: 70,
                widthPercent: 15,
                height: 48,
              ),
            ],
            selectedTab: 1,
            timeLabels: ['11:00', '12:00', '13:00', '14:00', '15:00'],
          ),
        ),
      ),
    );
  }
}
