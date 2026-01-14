import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_circular_progress_card.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/vertical_circular_progress_card_data.dart';

/// 睡眠追踪卡片示例
///
/// 展示如何使用 VerticalCircularProgressCard 公共小组件
class VerticalCircularProgressCardExample extends StatelessWidget {
  const VerticalCircularProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: Center(
          child: VerticalCircularProgressCard(
            data: VerticalCircularProgressCardData(
              mainValue: 3.57,
              statusLabel: 'Insomniac',
              weeklyProgress: [
                CircularProgressItemData(day: 'M', achieved: true, progress: 1.0),
                CircularProgressItemData(day: 'T', achieved: false, progress: 0.68),
                CircularProgressItemData(day: 'W', achieved: true, progress: 1.0),
                CircularProgressItemData(day: 'T', achieved: true, progress: 0.92),
                CircularProgressItemData(day: 'F', achieved: false, progress: 0.6),
                CircularProgressItemData(day: 'S', achieved: false, progress: 0.76),
                CircularProgressItemData(day: 'S', achieved: true, progress: 1.0),
              ],
            ),
            size: HomeWidgetSize.large,
          ),
        ),
      ),
    );
  }
}
