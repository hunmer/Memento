import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/bar_chart_stats_card.dart';

/// 柱状图统计卡片示例
class BarChartStatsCardExample extends StatelessWidget {
  const BarChartStatsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF3F5F9),
        child: const Center(
          child: BarChartStatsCardWidget(
            title: 'Sleep Time',
            dateRange: '12 - 19 January 2025',
            averageValue: 6.5,
            unit: 'hours',
            icon: Icons.bedtime,
            iconColor: Color(0xFF00C968),
            data: [
              3.2,
              5.2,
              9.5,
              5.8,
              3.2,
              9.2,
              7.2,
            ],
            labels: [
              '12/01',
              '13/01',
              '14/01',
              '15/01',
              '16/01',
              '17/01',
              '18/01',
            ],
            maxValue: 10,
          ),
        ),
      ),
    );
  }
}
