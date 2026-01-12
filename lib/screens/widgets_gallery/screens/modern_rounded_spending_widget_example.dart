import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/modern_rounded_spending_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/spending_category.dart';

/// 消费卡片示例
class ModernRoundedSpendingWidgetExample extends StatelessWidget {
  const ModernRoundedSpendingWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('消费卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        child: const Center(
          child: ModernRoundedSpendingWidget(
            title: 'Today Spending',
            currentSpending: 322.0,
            budget: 443.0,
            categories: [
              SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
              SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
              SpendingCategory(name: 'Transport', amount: 31.0, color: Color(0xFFFFCC00)),
              SpendingCategory(name: 'Other', amount: 11.0, color: Color(0xFF8E8E93)),
            ],
          ),
        ),
      ),
    );
  }
}
