import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/card_dot_progress_display.dart';

/// 活动进度卡片示例
class CardDotProgressDisplayExample extends StatelessWidget {
  const CardDotProgressDisplayExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('活动进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸 (1x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CardDotProgressDisplay(
                      title: 'Mileage',
                      subtitle: 'January 2025',
                      value: 153.20,
                      unit: 'km',
                      activities: 15,
                      totalProgress: 20,
                      completedProgress: 17,
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸 (2x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CardDotProgressDisplay(
                      title: 'Mileage',
                      subtitle: 'January 2025',
                      value: 153.20,
                      unit: 'km',
                      activities: 15,
                      totalProgress: 20,
                      completedProgress: 17,
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸 (2x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CardDotProgressDisplay(
                      title: 'Mileage',
                      subtitle: 'January 2025',
                      value: 153.20,
                      unit: 'km',
                      activities: 15,
                      totalProgress: 20,
                      completedProgress: 17,
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 220,
                    child: CardDotProgressDisplay(
                      title: 'Mileage',
                      subtitle: 'January 2025',
                      value: 153.20,
                      unit: 'km',
                      activities: 15,
                      totalProgress: 20,
                      completedProgress: 17,
                      size: const WideSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 320,
                    child: CardDotProgressDisplay(
                      title: 'Mileage',
                      subtitle: 'January 2025',
                      value: 153.20,
                      unit: 'km',
                      activities: 15,
                      totalProgress: 20,
                      completedProgress: 17,
                      size: const Wide2Size(),
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
