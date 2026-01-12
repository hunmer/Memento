import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/curve_progress_card.dart';

/// 曲线进度卡片示例
///
/// 展示如何使用 CurveProgressCardWidget 组件
class CurveProgressCardExample extends StatelessWidget {
  const CurveProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('曲线进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF2F6),
        child: const Center(
          child: CurveProgressCardWidget(
            value: 8524.0,
            label: 'Total Hours',
            change: 1248.0,
            changePercent: 17.15,
            unit: 'h',
            icon: Icons.schedule,
            categoryLabel: 'Progress',
            lastUpdated: 'Updated 2h ago',
          ),
        ),
      ),
    );
  }
}
