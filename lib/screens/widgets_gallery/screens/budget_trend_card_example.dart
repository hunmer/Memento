import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: BudgetTrendCardWidget(
                      size: HomeWidgetSize.small,
                      label: 'Budget',
                      value: 142000,
                      valuePrefix: r'$',
                      valueSuffix: '',
                      description: 'Total income',
                      chartData: const [35, 45, 35, 12, 20, 45],
                      changeValue: 40,
                      changePercent: 15.40,
                      updateTime: 'Updated 1hr ago',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: BudgetTrendCardWidget(
                      size: HomeWidgetSize.medium,
                      label: 'Budget',
                      value: 142000,
                      valuePrefix: r'$',
                      valueSuffix: '',
                      description: 'Total income',
                      chartData: const [35, 45, 35, 12, 20, 45],
                      changeValue: 40,
                      changePercent: 15.40,
                      updateTime: 'Updated 1hr ago',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: BudgetTrendCardWidget(
                      size: HomeWidgetSize.large,
                      label: 'Budget',
                      value: 142000,
                      valuePrefix: r'$',
                      valueSuffix: '',
                      description: 'Total income',
                      chartData: const [35, 45, 35, 12, 20, 45],
                      changeValue: 40,
                      changePercent: 15.40,
                      updateTime: 'Updated 1hr ago',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
