import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/line_chart_trend_card.dart';

/// 折线图趋势卡片示例
class LineChartTrendCardExample extends StatelessWidget {
  const LineChartTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('折线图趋势卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: LineChartTrendCardWidget(
            value: 2583,
            label: 'Earned',
            changePercent: -5.34,
            dataPoints: [85, 70, 78, 35, 45, 20, 65],
            unit: '\$',
          ),
        ),
      ),
    );
  }
}
