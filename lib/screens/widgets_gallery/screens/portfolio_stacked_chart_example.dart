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
                    child: PortfolioStackedChartWidget(
                      title: 'Overview',
                      totalAmount: 231471.24,
                      growthPercentage: 12,
                      assetTypes: const [
                        AssetType(label: 'Stocks', color: Color(0xFF94B8FF)),
                        AssetType(label: 'Funds', color: Color(0xFF2563EB)),
                      ],
                      monthlyData: const [
                        MonthlyData(stocks: 48, funds: 32, bonds: 32),
                        MonthlyData(stocks: 40, funds: 28, bonds: 36),
                        MonthlyData(stocks: 32, funds: 24, bonds: 32),
                      ],
                      monthLabels: const ['May', 'Jul', 'Oct'],
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
                    child: PortfolioStackedChartWidget(
                      title: 'Overview',
                      totalAmount: 231471.24,
                      growthPercentage: 12,
                      assetTypes: const [
                        AssetType(label: 'Stocks', color: Color(0xFF94B8FF)),
                        AssetType(label: 'Funds', color: Color(0xFF2563EB)),
                        AssetType(label: 'Bonds', color: Color(0xFF000000)),
                      ],
                      monthlyData: const [
                        MonthlyData(stocks: 48, funds: 32, bonds: 32),
                        MonthlyData(stocks: 40, funds: 28, bonds: 36),
                        MonthlyData(stocks: 32, funds: 24, bonds: 32),
                        MonthlyData(stocks: 24, funds: 20, bonds: 28),
                        MonthlyData(stocks: 16, funds: 20, bonds: 24),
                      ],
                      monthLabels: const ['May', 'Jul', 'Oct', 'Dec', 'Jan'],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 300,
                    child: PortfolioStackedChartWidget(
                      title: 'Overview',
                      totalAmount: 231471.24,
                      growthPercentage: 12,
                      assetTypes: const [
                        AssetType(label: 'Stocks', color: Color(0xFF94B8FF)),
                        AssetType(label: 'Funds', color: Color(0xFF2563EB)),
                        AssetType(label: 'Bonds', color: Color(0xFF000000)),
                      ],
                      monthlyData: const [
                        MonthlyData(stocks: 48, funds: 32, bonds: 32),
                        MonthlyData(stocks: 40, funds: 28, bonds: 36),
                        MonthlyData(stocks: 32, funds: 24, bonds: 32),
                        MonthlyData(stocks: 24, funds: 20, bonds: 28),
                        MonthlyData(stocks: 16, funds: 20, bonds: 24),
                        MonthlyData(stocks: 12, funds: 36, bonds: 28),
                        MonthlyData(stocks: 24, funds: 8, bonds: 28),
                      ],
                      monthLabels: const ['May', 'Jul', 'Oct', 'Dec', 'Jan', 'Mar', 'Apr'],
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
