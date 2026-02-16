import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/sleep_stage_chart_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 睡眠阶段图表示例
class SleepStageChartExample extends StatelessWidget {
  const SleepStageChartExample({super.key});

  static const List<SleepStageData> sampleStages = [
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
  ];

  static const List<String> sampleTimeLabels = [
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠阶段图表')),
      body: Container(
        color: isDark ? const Color(0xFFEBB305) : const Color(0xFFFDFDFD),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSizeSection(
                context,
                'Small Size (1x1)',
                const SizedBox(
                  width: 160,
                  child: SleepStageChartCard(
                    sleepStages: sampleStages,
                    size: SmallSize(),
                    timeLabels: sampleTimeLabels,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSizeSection(
                context,
                'Medium Size (2x1)',
                const SleepStageChartCard(
                  sleepStages: sampleStages,
                  size: MediumSize(),
                  timeLabels: sampleTimeLabels,
                ),
              ),
              const SizedBox(height: 24),
              _buildSizeSection(
                context,
                'Large Size (2x2)',
                const SleepStageChartCard(
                  sleepStages: sampleStages,
                  size: LargeSize(),
                  timeLabels: sampleTimeLabels,
                ),
              ),
              const SizedBox(height: 24),
              _buildSizeSection(
                context,
                'Wide Size (4x1)',
                SizedBox(
                  width: screenWidth - 32,
                  child: const SleepStageChartCard(
                    sleepStages: sampleStages,
                    size: WideSize(),
                    timeLabels: sampleTimeLabels,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSizeSection(
                context,
                'Wide2 Size (4x2)',
                SizedBox(
                  width: screenWidth - 32,
                  child: const SleepStageChartCard(
                    sleepStages: sampleStages,
                    size: Wide2Size(),
                    timeLabels: sampleTimeLabels,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSection(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Center(child: child),
      ],
    );
  }
}
