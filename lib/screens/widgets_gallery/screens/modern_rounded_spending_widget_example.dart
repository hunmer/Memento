import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/spending_category.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/modern_rounded_spending_widget.dart';

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
                    child: ModernRoundedSpendingWidget(
                      title: 'Today Spending',
                      currentSpending: 322.0,
                      budget: 443.0,
                      categories: const [
                        SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
                        SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
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
                    child: ModernRoundedSpendingWidget(
                      title: 'Today Spending',
                      currentSpending: 322.0,
                      budget: 443.0,
                      categories: const [
                        SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
                        SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
                        SpendingCategory(name: 'Transport', amount: 31.0, color: Color(0xFFFFCC00)),
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
                    child: ModernRoundedSpendingWidget(
                      title: 'Today Spending',
                      currentSpending: 322.0,
                      budget: 443.0,
                      categories: const [
                        SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
                        SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
                        SpendingCategory(name: 'Transport', amount: 31.0, color: Color(0xFFFFCC00)),
                        SpendingCategory(name: 'Other', amount: 11.0, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: ModernRoundedSpendingWidget(
                    title: 'Today Spending Overview',
                    currentSpending: 322.0,
                    budget: 443.0,
                    categories: const [
                      SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
                      SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
                      SpendingCategory(name: 'Transport', amount: 31.0, color: Color(0xFFFFCC00)),
                      SpendingCategory(name: 'Shopping', amount: 28.0, color: Color(0xFF34C759)),
                      SpendingCategory(name: 'Entertainment', amount: 15.0, color: Color(0xFFAF52DE)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: ModernRoundedSpendingWidget(
                    title: 'Today Spending Analysis',
                    currentSpending: 322.0,
                    budget: 443.0,
                    categories: const [
                      SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
                      SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
                      SpendingCategory(name: 'Transport', amount: 31.0, color: Color(0xFFFFCC00)),
                      SpendingCategory(name: 'Shopping', amount: 28.0, color: Color(0xFF34C759)),
                      SpendingCategory(name: 'Entertainment', amount: 15.0, color: Color(0xFFAF52DE)),
                      SpendingCategory(name: 'Healthcare', amount: 22.0, color: Color(0xFFFF9500)),
                    ],
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
