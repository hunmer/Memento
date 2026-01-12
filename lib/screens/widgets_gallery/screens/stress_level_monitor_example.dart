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
        child: const Center(
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
    );
  }

  /// "Today" 按钮点击回调
  static void _onTodayTap() {
    // 可以添加导航到详情页面的逻辑
    debugPrint('Today button tapped');
  }

  /// 柱状图点击回调
  static void _onBarTap(int index, WeeklyLevelData data) {
    // 可以添加显示该日详细信息的逻辑
    debugPrint('Bar tapped: index=$index, day=${data.day}, value=${data.value}');
  }
}
