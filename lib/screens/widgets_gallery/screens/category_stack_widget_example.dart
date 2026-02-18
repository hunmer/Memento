import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/category_stack_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
                    child: CategoryStackWidget(
                      title: 'Today Spending',
                      currentAmount: 322,
                      targetAmount: 443,
                      currency: r'$',
                      size: const SmallSize(),
                      categories: const [
                        CategoryData(label: 'House', amount: 31, color: Color(0xFFFFD60A), percentage: 0.45),
                        CategoryData(label: 'Food', amount: 37, color: Color(0xFFFF453A), percentage: 0.25),
                        CategoryData(label: 'Fitness', amount: 43, color: Color(0xFF0A84FF), percentage: 0.20),
                        CategoryData(label: 'Other', amount: 11, color: Color(0xFF8E8E93), percentage: 0.10),
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
                    child: CategoryStackWidget(
                      title: 'Today Spending',
                      currentAmount: 322,
                      targetAmount: 443,
                      currency: r'$',
                      size: const MediumSize(),
                      categories: const [
                        CategoryData(label: 'House', amount: 31, color: Color(0xFFFFD60A), percentage: 0.45),
                        CategoryData(label: 'Food', amount: 37, color: Color(0xFFFF453A), percentage: 0.25),
                        CategoryData(label: 'Fitness', amount: 43, color: Color(0xFF0A84FF), percentage: 0.20),
                        CategoryData(label: 'Other', amount: 11, color: Color(0xFF8E8E93), percentage: 0.10),
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
                    child: CategoryStackWidget(
                      title: 'Today Spending',
                      currentAmount: 322,
                      targetAmount: 443,
                      currency: r'$',
                      size: const LargeSize(),
                      categories: const [
                        CategoryData(label: 'House', amount: 31, color: Color(0xFFFFD60A), percentage: 0.45),
                        CategoryData(label: 'Food', amount: 37, color: Color(0xFFFF453A), percentage: 0.25),
                        CategoryData(label: 'Fitness', amount: 43, color: Color(0xFF0A84FF), percentage: 0.20),
                        CategoryData(label: 'Other', amount: 11, color: Color(0xFF8E8E93), percentage: 0.10),
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
                  child: CategoryStackWidget(
                    title: 'Today Spending Overview',
                    currentAmount: 322,
                    targetAmount: 443,
                    currency: r'$',
                    size: const WideSize(),
                    categories: const [
                      CategoryData(label: 'House', amount: 31, color: Color(0xFFFFD60A), percentage: 0.45),
                      CategoryData(label: 'Food', amount: 37, color: Color(0xFFFF453A), percentage: 0.25),
                      CategoryData(label: 'Fitness', amount: 43, color: Color(0xFF0A84FF), percentage: 0.20),
                      CategoryData(label: 'Other', amount: 11, color: Color(0xFF8E8E93), percentage: 0.10),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: CategoryStackWidget(
                    title: 'Complete Today Spending Analysis',
                    currentAmount: 322,
                    targetAmount: 443,
                    currency: r'$',
                    size: const Wide2Size(),
                    categories: const [
                      CategoryData(label: 'House', amount: 31, color: Color(0xFFFFD60A), percentage: 0.45),
                      CategoryData(label: 'Food', amount: 37, color: Color(0xFFFF453A), percentage: 0.25),
                      CategoryData(label: 'Fitness', amount: 43, color: Color(0xFF0A84FF), percentage: 0.20),
                      CategoryData(label: 'Other', amount: 11, color: Color(0xFF8E8E93), percentage: 0.10),
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
