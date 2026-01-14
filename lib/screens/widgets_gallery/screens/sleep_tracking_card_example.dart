import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_circular_progress_card.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/sleep_tracking_card_data.dart';

/// 睡眠追踪卡片示例
///
/// 展示如何使用 VerticalCircularProgressCard 公共小组件
class SleepTrackingCardExample extends StatelessWidget {
  const SleepTrackingCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: Center(
          child: VerticalCircularProgressCard(
            data: SleepTrackingCardData(
              sleepHours: 3.57,
              sleepLabel: 'Insomniac',
              weeklyProgress: [
                DaySleepData(day: 'M', achieved: true, progress: 1.0),
                DaySleepData(day: 'T', achieved: false, progress: 0.68),
                DaySleepData(day: 'W', achieved: true, progress: 1.0),
                DaySleepData(day: 'T', achieved: true, progress: 0.92),
                DaySleepData(day: 'F', achieved: false, progress: 0.6),
                DaySleepData(day: 'S', achieved: false, progress: 0.76),
                DaySleepData(day: 'S', achieved: true, progress: 1.0),
              ],
            ),
            size: HomeWidgetSize.large,
          ),
        ),
      ),
    );
  }
}
