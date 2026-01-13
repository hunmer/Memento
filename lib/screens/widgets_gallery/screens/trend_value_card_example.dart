import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/trend_value_card.dart';

/// 趋勢數值卡片示例
class TrendValueCardExample extends StatelessWidget {
  const TrendValueCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('趨勢數值卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TrendValueCardWidget(
            value: 167.4,
            unit: 'lbs',
            trendValue: -0.8,
            trendUnit: 'lbs',
            chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
            date: 'Jan 12, 2028',
            additionalInfo: ['26.1 BMI', 'Overweight'],
            trendLabel: 'vs last week',
            primaryColor: Color(0xFFF59E0B),
          ),
        ),
      ),
    );
  }
}
