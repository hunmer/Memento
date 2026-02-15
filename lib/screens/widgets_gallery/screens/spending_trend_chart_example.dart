import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    width: 280,
                    height: 200,
                    child: SpendingTrendChartWidget(
                      size: const SmallSize(),
                      dateRange: '1-15 October',
                      title: 'Spending',
                      currentMonthLabel: 'Oct',
                      previousMonthLabel: 'Sep',
                      budgetAmount: 3200,
                      budgetLabel: 'Budget',
                      startLabel: '1',
                      middleLabel: 'Today',
                      endLabel: '31',
                      currentMonthData: [3200, 2400],
                      previousMonthData: [2800, 2000],
                      currentPoint: 1600,
                      maxAmount: 4000,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 250,
                    child: SpendingTrendChartWidget(
                      size: const MediumSize(),
                      dateRange: '1-20 October 2025',
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
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 300,
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 300,
                  child: SpendingTrendChartWidget(
                    size: const WideSize(),
                    dateRange: '1-31 October 2025',
                    title: 'Spending Trends Overview',
                    currentMonthLabel: 'Oct 2025',
                    previousMonthLabel: 'Sep 2025',
                    budgetAmount: 3200,
                    budgetLabel: 'Monthly Budget',
                    startLabel: 'Oct 1',
                    middleLabel: 'Today',
                    endLabel: 'Oct 31',
                    currentMonthData: [3200, 2800, 2400, 2000, 1600, 1200, 800],
                    previousMonthData: [2800, 2400, 2000, 1600, 1200, 800, 400],
                    currentPoint: 1600,
                    maxAmount: 4000,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 380,
                  child: SpendingTrendChartWidget(
                    size: const Wide2Size(),
                    dateRange: '1-31 October 2025 - Complete Monthly Analysis',
                    title: 'Complete Spending Trends Analysis',
                    currentMonthLabel: 'October 2025',
                    previousMonthLabel: 'September 2025',
                    budgetAmount: 3200,
                    budgetLabel: 'Monthly Budget',
                    startLabel: 'Oct 1',
                    middleLabel: 'Mid Month',
                    endLabel: 'Oct 31',
                    currentMonthData: [3200, 2800, 2400, 2000, 1600, 1200, 800, 600, 400],
                    previousMonthData: [2800, 2400, 2000, 1600, 1200, 800, 400, 300, 200],
                    currentPoint: 1600,
                    maxAmount: 4000,
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
