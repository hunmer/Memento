import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/monthly_progress_with_dots_card.dart';

/// 月度进度圆点卡片示例
class MonthlyProgressWithDotsCardExample extends StatelessWidget {
  const MonthlyProgressWithDotsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('月度进度圆点卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
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
                    child: MonthlyProgressWithDotsCardWidget(
                      size: const SmallSize(),
                      title: 'September',
                      currentDay: 18,
                      totalDays: 31,
                      percentage: 58,
                      backgroundColor: const Color(0xFF148690),
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
                    child: MonthlyProgressWithDotsCardWidget(
                      size: const MediumSize(),
                      title: 'September',
                      currentDay: 18,
                      totalDays: 31,
                      percentage: 58,
                      backgroundColor: const Color(0xFF148690),
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
                    child: MonthlyProgressWithDotsCardWidget(
                      size: const LargeSize(),
                      title: 'September',
                      currentDay: 18,
                      totalDays: 31,
                      percentage: 58,
                      backgroundColor: const Color(0xFF148690),
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
