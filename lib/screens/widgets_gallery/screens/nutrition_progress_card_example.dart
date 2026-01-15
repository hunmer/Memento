import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/split_column_progress_bar_card.dart';

/// 营养进度卡片示例
class SplitColumnProgressBarCardExample extends StatelessWidget {
  const SplitColumnProgressBarCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('营养进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SplitColumnProgressBarCard(
            leftData: ColumnProgressData(current: 470, total: 1830, unit: 'Cal'),
            leftConfig: LeftSectionConfig(
              icon: '🔥',
              label: 'Calories',
            ),
            rightItems: [
              ProgressItemData(
                icon: '🍔',
                name: 'Protein',
                current: 66,
                total: 94,
                color: Color(0xFF34D399),
                subtitle: '早餐 / 午餐',
              ),
              ProgressItemData(
                icon: '🍉',
                name: 'Carbs',
                current: 35,
                total: 64,
                color: Color(0xFFFED7AA),
                subtitle: '全麦面包',
              ),
              ProgressItemData(
                icon: '🥛',
                name: 'Fats',
                current: 21,
                total: 32,
                color: Color(0xFF3B82F6),
                subtitle: '坚果 / 鳄梨',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
