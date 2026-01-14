import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/square_pill_progress_card.dart';

/// 药物追踪器卡片示例
class SquarePillProgressCardExample extends StatelessWidget {
  const SquarePillProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('药物追踪器卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: SquarePillProgressCard(
            medicationCount: 547,
            unit: 'meds',
            progress: 0.77,
          ),
        ),
      ),
    );
  }
}
