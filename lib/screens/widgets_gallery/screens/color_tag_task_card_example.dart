import 'package:Memento/screens/widgets_gallery/common_widgets/models/color_tag_task_card_data.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/color_tag_task_card.dart';

/// 彩色标签任务列表卡片示例
class ColorTagTaskCardExample extends StatelessWidget {
  const ColorTagTaskCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('彩色标签任务列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: Center(
          child: ColorTagTaskCardWidget(
            data: const ColorTagTaskCardData(
              taskCount: 56,
              label: 'Upcoming tasks',
              tasks: [
                ColorTagTaskItem(
                  title: 'Design mobile UI dashboard for iOS',
                  color: 0xFF3B82F6,
                  tag: 'Design',
                ),
                ColorTagTaskItem(
                  title: 'Calculate budget and contract',
                  color: 0xFFFB7185,
                  tag: 'Finance',
                ),
                ColorTagTaskItem(
                  title: 'Search for a UI kit',
                  color: 0xFFFBBF24,
                  tag: 'Research',
                ),
                ColorTagTaskItem(
                  title: 'Create HTML & CSS for startup',
                  color: 0xFF3B82F6,
                  tag: 'Dev',
                ),
                ColorTagTaskItem(
                  title: 'Design search page for website',
                  color: 0xFF34D399,
                  tag: 'Design',
                ),
                ColorTagTaskItem(
                  title: 'Send an estimate budget for app',
                  color: 0xFFFB7185,
                  tag: 'Finance',
                ),
                ColorTagTaskItem(
                  title: 'Search for a mobile UI kit',
                  color: 0xFFFBBF24,
                  tag: 'Research',
                ),
                ColorTagTaskItem(
                  title: 'Export assets for HTML developer',
                  color: 0xFF3B82F6,
                  tag: 'Dev',
                ),
              ],
              moreCount: 10,
            ),
          ),
        ),
      ),
    );
  }
}
