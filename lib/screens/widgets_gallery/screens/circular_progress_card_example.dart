import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/circular_progress_card.dart';

/// 圆形进度卡片示例
class CircularProgressCardExample extends StatelessWidget {
  const CircularProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆形进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CircularProgressCardWidget(
            title: '2020 Progress',
            subtitle: '157d/366d • Passed',
            percentage: 71.23,
            progress: 0.71,
          ),
        ),
      ),
    );
  }
}
