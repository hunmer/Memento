import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/curve_progress_card.dart';

/// 曲线进度卡片示例
class CurveProgressCardExample extends StatelessWidget {
  const CurveProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('曲线进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF2F6),
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
                    child: CurveProgressCardWidget(
                      size: const SmallSize(),
                      value: 8524.0,
                      label: 'Total Hours',
                      change: 1248.0,
                      changePercent: 17.15,
                      unit: 'h',
                      icon: Icons.schedule,
                      categoryLabel: 'Progress',
                      lastUpdated: 'Updated 2h ago',
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
                    child: CurveProgressCardWidget(
                      size: const MediumSize(),
                      value: 8524.0,
                      label: 'Total Hours',
                      change: 1248.0,
                      changePercent: 17.15,
                      unit: 'h',
                      icon: Icons.schedule,
                      categoryLabel: 'Progress',
                      lastUpdated: 'Updated 2h ago',
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
                    child: CurveProgressCardWidget(
                      size: const LargeSize(),
                      value: 8524.0,
                      label: 'Total Hours',
                      change: 1248.0,
                      changePercent: 17.15,
                      unit: 'h',
                      icon: Icons.schedule,
                      categoryLabel: 'Progress',
                      lastUpdated: 'Updated 2h ago',
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
