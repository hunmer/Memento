import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/segmented_progress_card.dart';

/// 分段进度条统计卡片示例
class SegmentedProgressCardExample extends StatelessWidget {
  const SegmentedProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分段进度条统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SegmentedProgressCardWidget(
            title: '今日支出',
            currentValue: 322,
            targetValue: 443,
            segments: [
              SegmentData(label: '餐饮', value: 37, color: Color(0xFFFF3B30)),
              SegmentData(label: '健身', value: 43, color: Color(0xFF007AFF)),
              SegmentData(label: '交通', value: 31, color: Color(0xFFFFCC00)),
              SegmentData(label: '其他', value: 11, color: Color(0xFF8E8E93)),
            ],
            unit: '\$',
          ),
        ),
      ),
    );
  }
}
