import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/budget_trend_card.dart';

/// 预算趋势卡片示例
class BudgetTrendCardExample extends StatelessWidget {
  const BudgetTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('预算趋势卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: BudgetTrendCardWidget(
            label: 'Budget',
            value: 142000,
            valuePrefix: r'$',
            valueSuffix: '',
            description: 'Total income',
            chartData: [35, 45, 35, 12, 20, 45],
            changeValue: 40,
            changePercent: 15.40,
            updateTime: 'Updated 1hr ago',
          ),
        ),
      ),
    );
  }
}
