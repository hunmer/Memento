import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 饮水追踪器示例
class HydrationTrackerWidgetExample extends StatelessWidget {
  const HydrationTrackerWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('饮水追踪器')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: HydrationTrackerCard(
            goal: 2.0,
            consumed: 0.7,
            unit: 'Liters',
            streakDays: 5,
          ),
        ),
      ),
    );
  }
}
