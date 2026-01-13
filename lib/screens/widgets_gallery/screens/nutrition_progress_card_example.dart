import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/nutrition_progress_card.dart';

/// 营养进度卡片示例
class NutritionProgressCardExample extends StatelessWidget {
  const NutritionProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('营养进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: NutritionProgressCardWidget(
            calories: NutritionData(current: 470, total: 1830, unit: 'Cal'),
            nutrients: [
              NutrientData(
                icon: '🍔',
                name: 'Protein',
                current: 66,
                total: 94,
                color: Color(0xFF34D399),
              ),
              NutrientData(
                icon: '🍉',
                name: 'Carbs',
                current: 35,
                total: 64,
                color: Color(0xFFFED7AA),
              ),
              NutrientData(
                icon: '🥛',
                name: 'Fats',
                current: 21,
                total: 32,
                color: Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
