import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/spending_trend_chart.dart';

/// 支出趋势折线图示例
class SpendingTrendChartExample extends StatelessWidget {
  const SpendingTrendChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('支出趋势折线图')),
      body: Container(
        color: isDark ? const Color(0xFF1a1c1a) : const Color(0xFFe2e8e4),
        child: const Center(
          child: SpendingTrendChartWidget(
            size: const LargeSize(),
            dateRange: '1-31 October 2025',
            title: 'Spending trends',
            currentMonthLabel: 'Oct 2025',
            previousMonthLabel: 'Sep 2025',
            budgetAmount: 3200,
            budgetLabel: 'Budget',
            startLabel: 'Oct 1',
            middleLabel: 'Today',
            endLabel: 'Oct 31',
            currentMonthData: [3200, 2800, 2400, 2000, 1600],
            previousMonthData: [2800, 2400, 2000, 1600, 1200],
            currentPoint: 1600,
            maxAmount: 4000,
          ),
        ),
      ),
    );
  }
}
