import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/earnings_trend_card.dart';

/// 收益趋势卡片示例
///
/// 展示如何使用 EarningsTrendCardWidget 组件
class EarningsTrendCardExample extends StatelessWidget {
  const EarningsTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收益趋势卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF2F6),
        child: const Center(
          child: EarningsTrendCardWidget(
            title: 'Expected earnings',
            value: 682.5,
            currency: '€',
            percentage: 2.45,
            chartData: [80, 90, 60, 40, 110, 110, 50, 40, 30, 70, 70, 40, 50],
          ),
        ),
      ),
    );
  }
}
