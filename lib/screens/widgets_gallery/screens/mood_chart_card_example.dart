import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/mood_chart_card.dart';

/// 心情图表卡片示例
class MoodChartCardExample extends StatelessWidget {
  const MoodChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('心情图表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MoodChartCardWidget(
            title: 'This Week',
            subtitle: 'Your Mood',
            moods: [
              MoodEntry(emoji: '😊', label: 'Mon', value: 12),
              MoodEntry(emoji: '😐', label: 'Tue', value: 8),
              MoodEntry(emoji: '😔', label: 'Wed', value: 5),
              MoodEntry(emoji: '😊', label: 'Thu', value: 15),
              MoodEntry(emoji: '😁', label: 'Fri', value: 18),
              MoodEntry(emoji: '😐', label: 'Sat', value: 10),
              MoodEntry(emoji: '😊', label: 'Sun', value: 14),
            ],
            displayType: MoodType.emoji,
          ),
        ),
      ),
    );
  }
}
