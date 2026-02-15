import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/index.dart';

/// 压力水平监测卡片小组件
///
/// 公共组件 LevelMonitorCard 的包装器，用于 widgets_gallery 兼容性。
/// 实际实现位于 `lib/widgets/common/level_monitor_card.dart`。
///
/// 显示当前分数、状态描述和每周7天的柱状图数据，支持动画效果。
@Deprecated('使用 lib/widgets/common 中的 LevelMonitorCard 代替')
class CardBarChartMonitor extends StatelessWidget {
  /// 标题
  final String title;

  /// 图标
  final IconData icon;

  /// 当前分数
  final double currentScore;

  /// 状态描述
  final String status;

  /// 分数单位
  final String scoreUnit;

  /// 每周数据
  final List<WeeklyLevelData> weeklyData;

  /// "Today" 按钮点击回调
  final VoidCallback? onTodayTap;

  /// 柱状图点击回调
  final Function(int index, WeeklyLevelData data)? onBarTap;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const CardBarChartMonitor({
    super.key,
    required this.title,
    required this.icon,
    required this.currentScore,
    required this.status,
    required this.scoreUnit,
    required this.weeklyData,
    this.onTodayTap,
    this.onBarTap,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory CardBarChartMonitor.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final weeklyDataList = props['weeklyData'] as List?;
    final weeklyData = weeklyDataList?.map((item) {
      return WeeklyLevelData.fromJson(item as Map<String, dynamic>);
    }).toList() ?? <WeeklyLevelData>[];

    return CardBarChartMonitor(
      title: props['title'] as String? ?? 'Stress Level',
      icon: _getIcon(props['icon'] as String? ?? 'error_outline'),
      currentScore: (props['currentScore'] as num?)?.toDouble() ?? 0.0,
      status: props['status'] as String? ?? '',
      scoreUnit: props['scoreUnit'] as String? ?? 'pts',
      weeklyData: weeklyData,
      onTodayTap: null, // 回调无法从 props 恢复
      onBarTap: null, // 回调无法从 props 恢复
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  /// 从图标代码获取 IconData
  static IconData _getIcon(String iconCode) {
    // 简化处理，返回默认图标
    return Icons.error_outline;
  }

  @override
  Widget build(BuildContext context) {
    return LevelMonitorCard(
      title: title,
      icon: icon,
      currentScore: currentScore,
      status: status,
      scoreUnit: scoreUnit,
      weeklyData: weeklyData,
      onTodayTap: onTodayTap ?? () {},
      onBarTap: onBarTap ?? (_, __) {},
      inline: inline,
      size: size,
    );
  }
}
