import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/chart_icon_display_card.dart';

/// 图标展示图表卡片示例
class ChartIconDisplayCardExample extends StatelessWidget {
  const ChartIconDisplayCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('心情图表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: ChartIconDisplayCard(
            title: 'This Week',
            subtitle: 'Your Mood',
            moods: [
              ChartIconEntry(emoji: '😊', label: 'Mon', value: 12),
              ChartIconEntry(emoji: '😐', label: 'Tue', value: 8),
              ChartIconEntry(emoji: '😔', label: 'Wed', value: 5),
              ChartIconEntry(emoji: '😊', label: 'Thu', value: 15),
              ChartIconEntry(emoji: '😁', label: 'Fri', value: 18),
              ChartIconEntry(emoji: '😐', label: 'Sat', value: 10),
              ChartIconEntry(emoji: '😊', label: 'Sun', value: 14),
            ],
            displayType: ChartIconType.emoji,
          ),
        ),
      ),
    );
  }
}
