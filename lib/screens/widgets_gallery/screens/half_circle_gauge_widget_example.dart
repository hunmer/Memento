import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/half_gauge_card.dart';

/// 半圆形统计小组件示例
///
/// 此示例展示如何使用 [HalfGaugeCardWidget] 组件
/// 该组件用于显示半圆形的预算/进度仪表盘
/// 展示三种尺寸：小、中、大
class HalfCircleGaugeWidgetExample extends StatelessWidget {
  const HalfCircleGaugeWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('半圆形统计小组件')),
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
                    child: HalfGaugeCardWidget(
                      title: 'Small',
                      totalBudget: 10000,
                      remaining: 5089.49,
                      currency: 'AED',
                      size: HomeWidgetSize.small,
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
                    child: HalfGaugeCardWidget(
                      title: 'Medium',
                      totalBudget: 10000,
                      remaining: 5089.49,
                      currency: 'AED',
                      size: HomeWidgetSize.medium,
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
                    child: HalfGaugeCardWidget(
                      title: 'Large',
                      totalBudget: 10000,
                      remaining: 5089.49,
                      currency: 'AED',
                      size: HomeWidgetSize.large,
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
