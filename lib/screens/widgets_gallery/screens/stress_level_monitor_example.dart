import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/index.dart';

/// 压力水平监测示例
///
/// 演示如何使用 [LevelMonitorCard] 组件展示压力水平数据
class StressLevelMonitorExample extends StatelessWidget {
  const StressLevelMonitorExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('压力水平监测')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
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
                    child: LevelMonitorCard(
                      title: 'Stress',
                      icon: Icons.error_outline,
                      currentScore: 4.2,
                      status: 'Stressed',
                      scoreUnit: 'pts',
                      size: const SmallSize(),
                      weeklyData: [
                        WeeklyLevelData(
                          day: 'M',
                          value: 0.45,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'T',
                          value: 0.25,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'W',
                          value: 0.60,
                          isSelected: true,
                        ),
                        WeeklyLevelData(
                          day: 'T',
                          value: 0.85,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'F',
                          value: 0.35,
                          isSelected: false,
                        ),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
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
                    child: LevelMonitorCard(
                      title: 'Stress Level',
                      icon: Icons.error_outline,
                      currentScore: 4.2,
                      status: 'Stressed Out',
                      scoreUnit: 'pts',
                      size: const MediumSize(),
                      weeklyData: [
                        WeeklyLevelData(
                          day: 'Mon',
                          value: 0.45,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Tue',
                          value: 0.25,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Wed',
                          value: 0.60,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Thu',
                          value: 0.85,
                          isSelected: true,
                        ),
                        WeeklyLevelData(
                          day: 'Fri',
                          value: 0.35,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Sat',
                          value: 0.15,
                          isSelected: false,
                        ),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
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
                    child: LevelMonitorCard(
                      title: 'Stress Level',
                      icon: Icons.error_outline,
                      currentScore: 4.2,
                      status: 'Stressed Out',
                      scoreUnit: 'pts',
                      size: const LargeSize(),
                      weeklyData: [
                        WeeklyLevelData(
                          day: 'Mon',
                          value: 0.45,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Tue',
                          value: 0.25,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Wed',
                          value: 0.60,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Thu',
                          value: 0.85,
                          isSelected: true,
                        ),
                        WeeklyLevelData(
                          day: 'Fri',
                          value: 0.35,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Sat',
                          value: 0.15,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Sun',
                          value: 0.40,
                          isSelected: false,
                        ),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: screenWidth - 32,
                    height: 220,
                    child: LevelMonitorCard(
                      inline: true,
                      title: 'Weekly Stress Level Monitor',
                      icon: Icons.monitor_heart,
                      currentScore: 4.2,
                      status: 'Stressed Out - Needs Attention',
                      scoreUnit: 'pts',
                      size: const WideSize(),
                      weeklyData: [
                        WeeklyLevelData(
                          day: 'Mon',
                          value: 0.45,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Tue',
                          value: 0.25,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Wed',
                          value: 0.60,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Thu',
                          value: 0.85,
                          isSelected: true,
                        ),
                        WeeklyLevelData(
                          day: 'Fri',
                          value: 0.35,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Sat',
                          value: 0.15,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Sun',
                          value: 0.40,
                          isSelected: false,
                        ),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: screenWidth - 32,
                    height: 320,
                    child: LevelMonitorCard(
                      inline: true,
                      title: 'Complete Stress Level Analysis and Monitoring',
                      icon: Icons.health_and_safety,
                      currentScore: 4.2,
                      status: 'Stressed Out - Requires Immediate Attention',
                      scoreUnit: 'pts',
                      size: const Wide2Size(),
                      weeklyData: [
                        WeeklyLevelData(
                          day: 'Monday',
                          value: 0.45,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Tuesday',
                          value: 0.25,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Wednesday',
                          value: 0.60,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Thursday',
                          value: 0.85,
                          isSelected: true,
                        ),
                        WeeklyLevelData(
                          day: 'Friday',
                          value: 0.35,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Saturday',
                          value: 0.15,
                          isSelected: false,
                        ),
                        WeeklyLevelData(
                          day: 'Sunday',
                          value: 0.40,
                          isSelected: false,
                        ),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
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

  /// "Today" 按钮点击回调
  static void _onTodayTap() {
    debugPrint('Today button tapped');
  }

  /// 柱状图点击回调
  static void _onBarTap(int index, WeeklyLevelData data) {
    debugPrint(
      'Bar tapped: index=$index, day=${data.day}, value=${data.value}',
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
