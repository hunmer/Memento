import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/weekly_bar_chart_card.dart';

/// 周条形图卡片示例
class WeeklyBarChartCardExample extends StatelessWidget {
  const WeeklyBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('周条形图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F8),
        child: const Center(
          child: CommonWeeklyBarChartCardWidget(
            title: 'Transactions',
            subtitle: 'vs last month',
            percentage: 54,
            weeklyData: [
              CommonWeeklyBarData(label: 'Mon', upperHeight: 0.40, lowerHeight: 0.35),
              CommonWeeklyBarData(label: 'Tue', upperHeight: 0.30, lowerHeight: 0.55),
              CommonWeeklyBarData(label: 'Wed', upperHeight: 0.25, lowerHeight: 0.35),
              CommonWeeklyBarData(label: 'Thu', upperHeight: 0.20, lowerHeight: 0.48),
              CommonWeeklyBarData(label: 'Fri', upperHeight: 0.20, lowerHeight: 0.60),
              CommonWeeklyBarData(label: 'Sat', upperHeight: 0.15, lowerHeight: 0.25),
              CommonWeeklyBarData(label: 'Sun', upperHeight: 0.30, lowerHeight: 0.45),
            ],
          ),
        ),
      ),
    );
  }
}
