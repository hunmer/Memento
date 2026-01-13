import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/activity_rings_card.dart';

/// 活动圆环卡片示例
class ActivityRingsCardExample extends StatelessWidget {
  const ActivityRingsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('活动圆环卡片')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          ),
        ),
        child: Center(
          child: ActivityRingsCardWidget(
            date: 'Jan 23, 2025',
            steps: 858,
            status: 'Normal',
            rings: [
              RingData(value: 70, color: const Color(0xFFF97316), icon: Icons.print),
              const RingData(value: 20, color: Color(0xFF2563EB), icon: null, isDiamond: true),
              const RingData(value: 40, color: Color(0xFF6B7280), icon: Icons.directions_run),
            ],
          ),
        ),
      ),
    );
  }
}
