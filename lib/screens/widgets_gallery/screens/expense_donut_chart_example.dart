import 'package:flutter/material.dart';
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
        child: const Center(
          child: ExpenseDonutChartWidget(
            badgeLabel: 'Expenses',
            timePeriod: 'In the past 7 days',
            totalAmount: 32,
            totalUnit: 'K',
            categories: [
              ExpenseCategoryData(label: 'Relax', percentage: 54, color: Color(0xFF2DD4BF)),
              ExpenseCategoryData(label: 'Food', percentage: 27, color: Color(0xFF8B5CF6)),
              ExpenseCategoryData(label: 'Transport', percentage: 12, color: Color(0xFFD8F57E)),
              ExpenseCategoryData(label: 'Pets', percentage: 7, color: Color(0xFFFDBA74)),
            ],
          ),
        ),
      ),
    );
  }
}
