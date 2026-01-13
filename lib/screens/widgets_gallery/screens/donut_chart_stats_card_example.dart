import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/donut_chart_stats_card.dart';

/// 甜甜圈图统计卡片示例
class DonutChartStatsCardExample extends StatelessWidget {
  const DonutChartStatsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('甜甜圈图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DonutChartStatsCardWidget(
            totalValue: 85964.45,
            unit: '',
            categories: [
              ChartCategoryData(
                label: 'Marketing Channels',
                value: 0.22,
                color: Color(0xFF4F46E5),
              ),
              ChartCategoryData(
                label: 'Direct Sales',
                value: 0.22,
                color: Color(0xFF6EE7B7),
              ),
              ChartCategoryData(
                label: 'Offline Channels',
                value: 0.44,
                color: Color(0xFFFBBF24),
              ),
              ChartCategoryData(
                label: 'Other Channels',
                value: 0.12,
                color: Color(0xFFF472B6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
