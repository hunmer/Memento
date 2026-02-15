import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/expense_donut_chart.dart';

/// 支出分类环形图示例
class ExpenseDonutChartExample extends StatelessWidget {
  const ExpenseDonutChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('支出分类环形图')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
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
                    child: ExpenseDonutChartWidget(
                      size: HomeWidgetSize.small,
                      badgeLabel: 'Expenses',
                      timePeriod: 'In the past 7 days',
                      totalAmount: 32,
                      totalUnit: 'K',
                      categories: const [
                        ExpenseCategoryData(label: 'Relax', percentage: 54, color: Color(0xFF2DD4BF)),
                        ExpenseCategoryData(label: 'Food', percentage: 27, color: Color(0xFF8B5CF6)),
                      ],
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
                    child: ExpenseDonutChartWidget(
                      size: HomeWidgetSize.medium,
                      badgeLabel: 'Expenses',
                      timePeriod: 'In the past 7 days',
                      totalAmount: 32,
                      totalUnit: 'K',
                      categories: const [
                        ExpenseCategoryData(label: 'Relax', percentage: 54, color: Color(0xFF2DD4BF)),
                        ExpenseCategoryData(label: 'Food', percentage: 27, color: Color(0xFF8B5CF6)),
                        ExpenseCategoryData(label: 'Transport', percentage: 12, color: Color(0xFFD8F57E)),
                      ],
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
                    child: ExpenseDonutChartWidget(
                      size: HomeWidgetSize.large,
                      badgeLabel: 'Expenses',
                      timePeriod: 'In the past 7 days',
                      totalAmount: 32,
                      totalUnit: 'K',
                      categories: const [
                        ExpenseCategoryData(label: 'Relax', percentage: 54, color: Color(0xFF2DD4BF)),
                        ExpenseCategoryData(label: 'Food', percentage: 27, color: Color(0xFF8B5CF6)),
                        ExpenseCategoryData(label: 'Transport', percentage: 12, color: Color(0xFFD8F57E)),
                        ExpenseCategoryData(label: 'Pets', percentage: 7, color: Color(0xFFFDBA74)),
                      ],
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
