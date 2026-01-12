import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/curve_progress_card.dart';

/// 曲线进度卡片示例
class CurveProgressCardExample extends StatelessWidget {
  const CurveProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('曲线进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CurveProgressCardWidget(
            value: 360,
            label: 'Tasks left',
            change: 40,
            changePercent: 15.40,
            unit: '',
            icon: Icons.schedule,
            categoryLabel: 'Progress',
            lastUpdated: 'Updated 1hr ago',
          ),
        ),
      ),
    );
  }
}
