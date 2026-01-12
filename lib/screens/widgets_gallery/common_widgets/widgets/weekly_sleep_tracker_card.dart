import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/index.dart';

/// 睡眠追踪卡片小组件
///
/// 公共组件的包装器，用于 widgets_gallery 兼容性。
/// 实际实现位于 `lib/widgets/common/weekly_sleep_tracker_card.dart`。
///
/// 显示总睡眠时长、状态标签和每周7天的进度环。
@Deprecated('使用 lib/widgets/common 中的 WeeklySleepTrackerCard 代替')
class WeeklySleepTrackerCardWidget extends StatelessWidget {
  /// 总睡眠时长（小时）
  final double totalHours;

  /// 状态标签（如 "Insomniac"）
  final String statusLabel;

  /// 每周数据（7天）
  final List<DaySleepData> weeklyData;

  /// 主色调
  final Color? primaryColor;

  const WeeklySleepTrackerCardWidget({
    super.key,
    required this.totalHours,
    required this.statusLabel,
    required this.weeklyData,
    this.primaryColor,
  });

  /// 从 props 创建实例
  factory WeeklySleepTrackerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final weeklyDataList = props['weeklyData'] as List?;
    final weeklyData = weeklyDataList?.map((item) {
      return DaySleepData.fromJson(item as Map<String, dynamic>);
    }).toList() ?? <DaySleepData>[];

    return WeeklySleepTrackerCardWidget(
      totalHours: (props['totalHours'] as num?)?.toDouble() ?? 0.0,
      statusLabel: props['statusLabel'] as String? ?? '',
      weeklyData: weeklyData,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WeeklySleepTrackerCard(
      totalHours: totalHours,
      statusLabel: statusLabel,
      weeklyData: weeklyData,
      primaryColor: primaryColor,
    );
  }
}
