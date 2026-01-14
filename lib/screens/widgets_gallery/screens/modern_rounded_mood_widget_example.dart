import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/modern_rounded_bar_icon_card.dart';

/// 现代化圆角心情追踪小组件示例
class ModernRoundedBarIconCardExample extends StatelessWidget {
  const ModernRoundedBarIconCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('现代化心情追踪小组件'),
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFDBE6D1),
      ),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFDBE6D1),
        child: const Center(
          child: ModernRoundedBarIconCard(
            weekMoods: [
              BarIconEntry(dayLabel: 'M', positiveValue: 0.15, negativeValue: 0.0, moodType: BarIconType.positive),
              BarIconEntry(dayLabel: 'T', positiveValue: 0.25, negativeValue: 0.0, moodType: BarIconType.positive),
              BarIconEntry(dayLabel: 'W', positiveValue: 0.40, negativeValue: 0.0, moodType: BarIconType.positive),
              BarIconEntry(dayLabel: 'T', positiveValue: 0.65, negativeValue: 0.0, moodType: BarIconType.positive),
              BarIconEntry(dayLabel: 'F', positiveValue: 0.85, negativeValue: 0.0, moodType: BarIconType.positive, isToday: true),
              BarIconEntry(dayLabel: 'S', positiveValue: 0.0, negativeValue: 0.15, moodType: BarIconType.negative),
              BarIconEntry(dayLabel: 'S', positiveValue: 0.0, negativeValue: 0.55, moodType: BarIconType.negative),
            ],
          ),
        ),
      ),
    );
  }
}
