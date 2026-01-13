import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/revenue_trend_card.dart';

/// 收入趋势卡片示例
class RevenueTrendCardExample extends StatelessWidget {
  const RevenueTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收入趋势卡片')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFE5E5E5),
        child: const Center(
          child: RevenueTrendCardWidget(
            value: 145.32,
            currency: '\$',
            percentage: 12,
            period: 'Weekly',
            chartData: [80, 70, 90, 75, 60, 50, 40],
            dates: [22, 23, 24, 25, 26],
            highlightIndex: 4,
          ),
        ),
      ),
    );
  }
}
