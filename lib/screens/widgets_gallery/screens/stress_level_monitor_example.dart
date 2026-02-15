import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 压力水平监测示例
///
/// 演示如何使用 [LevelMonitorCard] 组件展示压力水平数据
class StressLevelMonitorExample extends StatelessWidget {
  const StressLevelMonitorExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 200,
                    child: LevelMonitorCard(
                      title: 'Stress',
                      icon: Icons.error_outline,
                      currentScore: 4.2,
                      status: 'Stressed',
                      scoreUnit: 'pts',
                      weeklyData: [
                        WeeklyLevelData(day: 'M', value: 0.45, isSelected: false),
                        WeeklyLevelData(day: 'T', value: 0.25, isSelected: false),
                        WeeklyLevelData(day: 'W', value: 0.60, isSelected: true),
                        WeeklyLevelData(day: 'T', value: 0.85, isSelected: false),
                        WeeklyLevelData(day: 'F', value: 0.35, isSelected: false),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 250,
                    child: LevelMonitorCard(
                      title: 'Stress Level',
                      icon: Icons.error_outline,
                      currentScore: 4.2,
                      status: 'Stressed Out',
                      scoreUnit: 'pts',
                      weeklyData: [
                        WeeklyLevelData(day: 'Mon', value: 0.45, isSelected: false),
                        WeeklyLevelData(day: 'Tue', value: 0.25, isSelected: false),
                        WeeklyLevelData(day: 'Wed', value: 0.60, isSelected: false),
                        WeeklyLevelData(day: 'Thu', value: 0.85, isSelected: true),
                        WeeklyLevelData(day: 'Fri', value: 0.35, isSelected: false),
                        WeeklyLevelData(day: 'Sat', value: 0.15, isSelected: false),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 300,
                    child: LevelMonitorCard(
                      title: 'Stress Level',
                      icon: Icons.error_outline,
                      currentScore: 4.2,
                      status: 'Stressed Out',
                      scoreUnit: 'pts',
                      weeklyData: [
                        WeeklyLevelData(day: 'Mon', value: 0.45, isSelected: false),
                        WeeklyLevelData(day: 'Tue', value: 0.25, isSelected: false),
                        WeeklyLevelData(day: 'Wed', value: 0.60, isSelected: false),
                        WeeklyLevelData(day: 'Thu', value: 0.85, isSelected: true),
                        WeeklyLevelData(day: 'Fri', value: 0.35, isSelected: false),
                        WeeklyLevelData(day: 'Sat', value: 0.15, isSelected: false),
                        WeeklyLevelData(day: 'Sun', value: 0.40, isSelected: false),
                      ],
                      onTodayTap: _onTodayTap,
                      onBarTap: _onBarTap,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: LevelMonitorCard(
                    title: 'Weekly Stress Level Monitor',
                    icon: Icons.monitor_heart,
                    currentScore: 4.2,
                    status: 'Stressed Out - Needs Attention',
                    scoreUnit: 'pts',
                    weeklyData: [
                      WeeklyLevelData(day: 'Mon', value: 0.45, isSelected: false),
                      WeeklyLevelData(day: 'Tue', value: 0.25, isSelected: false),
                      WeeklyLevelData(day: 'Wed', value: 0.60, isSelected: false),
                      WeeklyLevelData(day: 'Thu', value: 0.85, isSelected: true),
                      WeeklyLevelData(day: 'Fri', value: 0.35, isSelected: false),
                      WeeklyLevelData(day: 'Sat', value: 0.15, isSelected: false),
                      WeeklyLevelData(day: 'Sun', value: 0.40, isSelected: false),
                    ],
                    onTodayTap: _onTodayTap,
                    onBarTap: _onBarTap,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: LevelMonitorCard(
                    title: 'Complete Stress Level Analysis and Monitoring',
                    icon: Icons.health_and_safety,
                    currentScore: 4.2,
                    status: 'Stressed Out - Requires Immediate Attention',
                    scoreUnit: 'pts',
                    weeklyData: [
                      WeeklyLevelData(day: 'Monday', value: 0.45, isSelected: false),
                      WeeklyLevelData(day: 'Tuesday', value: 0.25, isSelected: false),
                      WeeklyLevelData(day: 'Wednesday', value: 0.60, isSelected: false),
                      WeeklyLevelData(day: 'Thursday', value: 0.85, isSelected: true),
                      WeeklyLevelData(day: 'Friday', value: 0.35, isSelected: false),
                      WeeklyLevelData(day: 'Saturday', value: 0.15, isSelected: false),
                      WeeklyLevelData(day: 'Sunday', value: 0.40, isSelected: false),
                    ],
                    onTodayTap: _onTodayTap,
                    onBarTap: _onBarTap,
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
    debugPrint('Bar tapped: index=$index, day=${data.day}, value=${data.value}');
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
