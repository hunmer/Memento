import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/index.dart';

/// 连续打卡追踪器示例
class HabitStreakTrackerExample extends StatelessWidget {
  const HabitStreakTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('连续打卡追踪器')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸 (SmallSize)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: HabitStreakTracker(
                      currentStreak: 5,
                      longestStreak: 15,
                      totalDays: 10,
                      completedDays: const [1, 2, 3, 4, 5],
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸 (MediumSize)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: HabitStreakTracker(
                      currentStreak: 5,
                      longestStreak: 15,
                      totalDays: 10,
                      completedDays: const [1, 2, 3, 4, 5],
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸 (LargeSize)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: HabitStreakTracker(
                      currentStreak: 5,
                      longestStreak: 15,
                      totalDays: 10,
                      completedDays: const [1, 2, 3, 4, 5],
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (WideSize)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 200,
                  child: HabitStreakTracker(
                    currentStreak: 5,
                    longestStreak: 15,
                    totalDays: 10,
                    completedDays: const [1, 2, 3, 4, 5],
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (Wide2Size)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: HabitStreakTracker(
                    currentStreak: 5,
                    longestStreak: 15,
                    totalDays: 10,
                    completedDays: const [1, 2, 3, 4, 5],
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
