import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/card_dot_progress_display.dart';

/// 活动进度卡片示例
class CardDotProgressDisplayExample extends StatelessWidget {
  const CardDotProgressDisplayExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('活动进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CardDotProgressDisplay(
            title: 'Mileage',
            subtitle: 'January 2025',
            value: 153.20,
            unit: 'km',
            activities: 15,
            totalProgress: 20,
            completedProgress: 17,
          ),
        ),
      ),
    );
  }
}
