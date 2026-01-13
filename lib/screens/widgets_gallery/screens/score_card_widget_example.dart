import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/score_card_widget.dart';

/// 分数卡片示例
class ScoreCardWidgetExample extends StatelessWidget {
  const ScoreCardWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分数卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: ScoreCardWidget(
            score: 912,
            grade: 'A',
            actions: [
              ActionData(label: 'Charity Pay', value: 16, isPositive: true),
              ActionData(
                label: 'Traffic Violation',
                value: 24,
                isPositive: false,
              ),
              ActionData(label: 'Blood Donation', value: 42, isPositive: true),
              ActionData(label: 'Volunteering', value: 32, isPositive: true),
            ],
          ),
        ),
      ),
    );
  }
}
