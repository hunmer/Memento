import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/modern_flip_counter_card.dart';

/// 现代 eGFR 健康指标卡片示例
class ModernFlipCounterCardExample extends StatelessWidget {
  const ModernFlipCounterCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('eGFR 健康指标卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: ModernFlipCounterCard(
            title: 'eGFR - Low Range',
            value: 4.2,
            unit: 'mL/min',
            date: 'September 2026',
            status: 'In-Range',
          ),
        ),
      ),
    );
  }
}
