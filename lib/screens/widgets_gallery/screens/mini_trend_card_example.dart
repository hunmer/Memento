import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/mini_trend_card.dart';

/// 迷你趋势卡片示例
class MiniTrendCardExample extends StatelessWidget {
  const MiniTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('迷你趋势卡片')),
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
                    child: MiniTrendCardWidget(
                      size: const SmallSize(),
                      title: 'Heart Rate',
                      icon: Icons.monitor_heart,
                      currentValue: 72,
                      unit: 'bpm',
                      subtitle: 'Resting Rate',
                      weekDays: const ['M', 'T', 'W'],
                      trendData: const [20, 22, 15],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: MiniTrendCardWidget(
                      size: const MediumSize(),
                      title: 'Heart Rate',
                      icon: Icons.monitor_heart,
                      currentValue: 72,
                      unit: 'bpm',
                      subtitle: 'Resting Rate',
                      weekDays: const ['M', 'T', 'W', 'T', 'F'],
                      trendData: const [20, 22, 15, 35, 25],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: MiniTrendCardWidget(
                      size: const LargeSize(),
                      title: 'Heart Rate',
                      icon: Icons.monitor_heart,
                      currentValue: 72,
                      unit: 'bpm',
                      subtitle: 'Resting Rate',
                      weekDays: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                      trendData: const [20, 22, 15, 35, 25, 35, 28],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 200,
                  child: MiniTrendCardWidget(
                    size: const WideSize(),
                    title: 'Heart Rate Monitor',
                    icon: Icons.monitor_heart,
                    currentValue: 72,
                    unit: 'bpm',
                    subtitle: 'Resting Heart Rate Tracking',
                    weekDays: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                    trendData: const [20, 22, 15, 35, 25, 35, 28, 30, 25],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: MiniTrendCardWidget(
                    size: const Wide2Size(),
                    title: 'Heart Rate Monitor',
                    icon: Icons.monitor_heart,
                    currentValue: 72,
                    unit: 'bpm',
                    subtitle: 'Resting Heart Rate Tracking and Analysis',
                    weekDays: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                    trendData: const [20, 22, 15, 35, 25, 35, 28, 30, 25, 32, 27, 35, 28],
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
