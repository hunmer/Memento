import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/sleep_duration_card.dart';

/// 睡眠时长统计卡片示例
class SleepDurationCardExample extends StatelessWidget {
  const SleepDurationCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠时长统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SleepDurationCardWidget(
            durationInMinutes: 435, // 7小时15分钟
            trend: SleepTrend.up,
          ),
        ),
      ),
    );
  }
}
