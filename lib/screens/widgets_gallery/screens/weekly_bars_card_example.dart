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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: WeeklyBarsCardWidget(
                      title: 'Hydration',
                      icon: Icons.water_drop,
                      currentValue: 1285,
                      unit: 'ml',
                      status: 'On Track',
                      dailyValues: [0.60, 0.45, 0.30, 0.55, 0.80, 0.90, 0.40],
                      primaryColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: WeeklyBarsCardWidget(
                      title: 'Hydration',
                      icon: Icons.water_drop,
                      currentValue: 1285,
                      unit: 'ml',
                      status: 'On Track',
                      dailyValues: [0.60, 0.45, 0.30, 0.55, 0.80, 0.90, 0.40],
                      primaryColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: WeeklyBarsCardWidget(
                      title: 'Hydration',
                      icon: Icons.water_drop,
                      currentValue: 1285,
                      unit: 'ml',
                      status: 'On Track',
                      dailyValues: [0.60, 0.45, 0.30, 0.55, 0.80, 0.90, 0.40],
                      primaryColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
