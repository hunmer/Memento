import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/stacked_ring_chart_card.dart';

/// 堆叠环形图统计卡片示例
class StackedRingChartExample extends StatelessWidget {
  const StackedRingChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('堆叠环形图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFE0E5EC),
        child: const Center(
          child: StackedRingChartCardWidget(
            segments: [
              RingSegmentData(label: 'Documents', value: 30, color: Color(0xFF0B1556)),
              RingSegmentData(label: 'Videos', value: 155, color: Color(0xFF00A9CE)),
              RingSegmentData(label: 'Photos', value: 80, color: Color(0xFF00649F)),
              RingSegmentData(label: 'Music', value: 193.5, color: Color(0xFF8AD6E9)),
            ],
            total: 251.2,
            title: 'Storage of your device',
            usedValue: 137,
            unit: 'GB',
            usedLabel: 'Used storage',
          ),
        ),
      ),
    );
  }
}
