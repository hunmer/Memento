import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_reflection_card.dart';

/// 每日反思卡片示例
class DailyReflectionCardExample extends StatelessWidget {
  const DailyReflectionCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日反思卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DailyReflectionCardWidget(
            dayOfWeek: 'Monday',
            question: 'How will you make tomorrow meaningful?',
          ),
        ),
      ),
    );
  }
}
