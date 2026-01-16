import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 体重追踪小组件示例
///
/// 此示例展示如何使用 [WeightTrackingCard] 可复用组件。
/// 该组件用于展示体重数据追踪与目标警戒线展示。
///
/// 功能特性：
/// - 支持直接使用参数创建组件
/// - 支持使用 [WeightTrackingData] 数据模型
/// - 支持数据模型与 JSON 之间的序列化/反序列化
/// - 完整的动画效果（淡入、缩放、柱状图逐个显示）
class WeightTrackingWidgetExample extends StatelessWidget {
  const WeightTrackingWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('体重追踪柱状图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF09090B) : const Color(0xFFF3F4F6),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 方式一：直接使用参数
              const WeightTrackingCard(
                currentWeight: 89.5,
                weightChange: -0.5,
                targetWeight: 92.0,
                data: [
                  89.2,
                  89.8,
                  90.5,
                  91.2,
                  90.8,
                  91.5,
                  90.2,
                  89.5,
                  88.8,
                  89.3,
                  88.5,
                  89.8,
                  90.5,
                  91.0,
                  90.2,
                  89.5,
                  88.9,
                  89.4,
                  90.1,
                  90.8,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
