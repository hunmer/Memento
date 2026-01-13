import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/medication_tracker_widget.dart';

/// 药物追踪器卡片示例
class MedicationTrackerWidgetExample extends StatelessWidget {
  const MedicationTrackerWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('药物追踪器卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: MedicationTrackerWidget(
            medicationCount: 547,
            unit: 'meds',
            progress: 0.77,
          ),
        ),
      ),
    );
  }
}
