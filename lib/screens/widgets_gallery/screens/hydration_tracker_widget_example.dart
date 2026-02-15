import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 饮水追踪器示例
class HydrationTrackerWidgetExample extends StatelessWidget {
  const HydrationTrackerWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('饮水追踪器')),
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
                    child: HydrationTrackerCard(
                      goal: 2.0,
                      consumed: 0.7,
                      unit: 'Liters',
                      streakDays: 5,
                      size: const SmallSize(),
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
                    child: HydrationTrackerCard(
                      goal: 2.0,
                      consumed: 0.7,
                      unit: 'Liters',
                      streakDays: 5,
                      size: const MediumSize(),
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
                    child: HydrationTrackerCard(
                      goal: 2.0,
                      consumed: 0.7,
                      unit: 'Liters',
                      streakDays: 5,
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 220,
                  child: HydrationTrackerCard(
                    goal: 2.0,
                    consumed: 0.7,
                    unit: 'Liters',
                    streakDays: 5,
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 320,
                  child: HydrationTrackerCard(
                    goal: 2.0,
                    consumed: 0.7,
                    unit: 'Liters',
                    streakDays: 5,
                    size: const Wide2Size(),
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
