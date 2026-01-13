import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/category_stack_widget.dart';

/// 分类堆叠消费卡片示例
class CategoryStackWidgetExample extends StatelessWidget {
  const CategoryStackWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分类堆叠消费卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CategoryStackWidget(
            title: 'Today Spending',
            currentAmount: 322,
            targetAmount: 443,
            currency: '\$',
            categories: [
              CategoryData(label: 'House', amount: 31, color: Color(0xFFFFD60A), percentage: 0.45),
              CategoryData(label: 'Food', amount: 37, color: Color(0xFFFF453A), percentage: 0.25),
              CategoryData(label: 'Fitness', amount: 43, color: Color(0xFF0A84FF), percentage: 0.20),
              CategoryData(label: 'Other', amount: 11, color: Color(0xFF8E8E93), percentage: 0.10),
            ],
          ),
        ),
      ),
    );
  }
}
