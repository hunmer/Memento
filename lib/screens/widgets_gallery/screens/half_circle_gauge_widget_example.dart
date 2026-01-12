import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/half_gauge_card.dart';

/// 半圆形统计小组件示例
///
/// 此示例展示如何使用 [HalfGaugeCardWidget] 组件
/// 该组件用于显示半圆形的预算/进度仪表盘
class HalfCircleGaugeWidgetExample extends StatelessWidget {
  const HalfCircleGaugeWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('半圆形统计小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: HalfGaugeCardWidget(
              title: 'Shopping',
              totalBudget: 10000,
              remaining: 5089.49,
              currency: 'AED',
            ),
          ),
        ),
      ),
    );
  }
}
