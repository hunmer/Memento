import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_bar_chart_card.dart';

/// 每日条形图卡片示例
class DailyBarChartCardExample extends StatelessWidget {
  const DailyBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日条形图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DailyBarChartCardWidget(
            title: 'Monthly Steps',
            subtitle: 'January 2025',
            value: 187297,
            unit: 'steps',
            bars: [
              DailyBarData(height: 0.30, color: DailyBarColor.red),
              DailyBarData(height: 0.45, color: DailyBarColor.red),
              DailyBarData(height: 0.65, color: DailyBarColor.teal),
              DailyBarData(height: 0.25, color: DailyBarColor.red),
              DailyBarData(height: 0.40, color: DailyBarColor.red),
              DailyBarData(height: 0.70, color: DailyBarColor.teal),
              DailyBarData(height: 0.55, color: DailyBarColor.teal),
              DailyBarData(height: 0.15, color: DailyBarColor.red),
              DailyBarData(height: 0.85, color: DailyBarColor.teal),
              DailyBarData(height: 0.35, color: DailyBarColor.red),
              DailyBarData(height: 0.20, color: DailyBarColor.red),
              DailyBarData(height: 0.60, color: DailyBarColor.teal),
              DailyBarData(height: 0.52, color: DailyBarColor.teal),
              DailyBarData(height: 0.90, color: DailyBarColor.teal),
              DailyBarData(height: 0.40, color: DailyBarColor.red),
              DailyBarData(height: 0.32, color: DailyBarColor.red),
              DailyBarData(height: 0.75, color: DailyBarColor.teal),
              DailyBarData(height: 0.28, color: DailyBarColor.red),
              DailyBarData(height: 0.48, color: DailyBarColor.red),
              DailyBarData(height: 0.62, color: DailyBarColor.teal),
              DailyBarData(height: 0.88, color: DailyBarColor.teal),
              DailyBarData(height: 0.72, color: DailyBarColor.teal),
              DailyBarData(height: 0.38, color: DailyBarColor.red),
              DailyBarData(height: 0.18, color: DailyBarColor.red),
              DailyBarData(height: 0.42, color: DailyBarColor.red),
              DailyBarData(height: 0.58, color: DailyBarColor.teal),
              DailyBarData(height: 0.82, color: DailyBarColor.teal),
              DailyBarData(height: 0.68, color: DailyBarColor.teal),
              DailyBarData(height: 0.55, color: DailyBarColor.teal),
            ],
          ),
        ),
      ),
    );
  }
}
