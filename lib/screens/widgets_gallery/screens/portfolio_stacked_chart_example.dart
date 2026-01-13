import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/portfolio_stacked_chart.dart';

/// 投资组合堆叠图示例
class PortfolioStackedChartExample extends StatelessWidget {
  const PortfolioStackedChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('投资组合堆叠图')),
      body: Container(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF3F4F6),
        child: const Center(
          child: PortfolioStackedChartWidget(
            title: 'Overview',
            totalAmount: 231471.24,
            growthPercentage: 12,
            assetTypes: [
              AssetType(label: 'Stocks', color: Color(0xFF94B8FF)),
              AssetType(label: 'Funds', color: Color(0xFF2563EB)),
              AssetType(label: 'Bonds', color: Color(0xFF000000)),
            ],
            monthlyData: [
              MonthlyData(stocks: 48, funds: 32, bonds: 32),
              MonthlyData(stocks: 40, funds: 28, bonds: 36),
              MonthlyData(stocks: 32, funds: 24, bonds: 32),
              MonthlyData(stocks: 24, funds: 20, bonds: 28),
              MonthlyData(stocks: 16, funds: 20, bonds: 24),
              MonthlyData(stocks: 12, funds: 36, bonds: 28),
              MonthlyData(stocks: 24, funds: 8, bonds: 28),
              MonthlyData(stocks: 20, funds: 8, bonds: 32),
              MonthlyData(stocks: 16, funds: 6, bonds: 24),
              MonthlyData(stocks: 12, funds: 8, bonds: 28),
              MonthlyData(stocks: 8, funds: 4, bonds: 24),
              MonthlyData(stocks: 16, funds: 12, bonds: 24),
              MonthlyData(stocks: 32, funds: 16, bonds: 28),
              MonthlyData(stocks: 20, funds: 20, bonds: 24),
              MonthlyData(stocks: 24, funds: 8, bonds: 24),
            ],
            monthLabels: ['May', 'Jul', 'Oct'],
          ),
        ),
      ),
    );
  }
}
