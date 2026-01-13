import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/multi_metric_progress_card.dart';

/// 多指标进度卡片示例
class MultiMetricProgressCardExample extends StatelessWidget {
  const MultiMetricProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('多指标进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MultiMetricProgressCardWidget(
            trackers: [
              MetricProgressData(
                emoji: '🐱',
                progress: 88.0,
                progressColor: Color(0xFFFFD60A),
                title: "Peach's Life",
                subtitle: 'July 21, 2019 • 321 days',
                value: 0.88,
                unit: 'years old',
              ),
              MetricProgressData(
                emoji: '📅',
                progress: 71.23,
                progressColor: Color(0xFFFFD60A),
                title: '2020 Progress',
                subtitle: '157d/366d • Passed',
                value: 71.23,
                unit: '%',
              ),
              MetricProgressData(
                emoji: '🏡',
                progress: 65.5,
                progressColor: Color(0xFF34C759),
                title: 'Work from home',
                subtitle: 'Jan 22, 2020 • Passed',
                value: 239,
                unit: 'days',
              ),
            ],
            backgroundColor: Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }
}
