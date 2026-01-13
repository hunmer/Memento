import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/weekly_bars_card.dart';

/// 周柱状图卡片示例
class WeeklyBarsCardExample extends StatelessWidget {
  const WeeklyBarsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('周柱状图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: WeeklyBarsCardWidget(
            title: 'Hydration',
            icon: Icons.water_drop,
            currentValue: 1285,
            unit: 'ml',
            status: 'On Track',
            dailyValues: [0.60, 0.45, 0.30, 0.55, 0.80, 0.90, 0.40],
            primaryColor: Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }
}
