import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/dot_tracker_card.dart';

/// 周度点追踪卡片适配器
///
/// 包装 lib/widgets/common/dot_tracker_card.dart 中的 DotTrackerCardWidget
/// 使其符合公共小组件系统的接口规范
class WeeklyDotTrackerCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;
  final HomeWidgetSize size;

  const WeeklyDotTrackerCardWidget({
    super.key,
    required this.props,
    required this.size,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory WeeklyDotTrackerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return WeeklyDotTrackerCardWidget(
      props: props,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String? ?? '周度追踪';
    final checkedDays = props['checkedDays'] as int? ?? 0;
    final weekData = (props['weekData'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // 从 weekData 提取数据
    final weekDays = <String>[];
    final dotStates = <List<bool>>[];

    for (final dayData in weekData) {
      final day = dayData['day'] as String? ?? '';
      final isChecked = dayData['isChecked'] as bool? ?? false;

      // 提取星期标签（周一、周二...）
      if (day.isNotEmpty) {
        weekDays.add(day.replaceAll('周', ''));
      }

      // 每天使用单个点状态
      dotStates.add([isChecked]);
    }

    // 如果 weekData 为空，使用默认7天
    if (weekDays.isEmpty) {
      weekDays.addAll(['一', '二', '三', '四', '五', '六', '日']);
      for (int i = 0; i < 7; i++) {
        dotStates.add([false]);
      }
    }

    // 计算状态文本
    final percentage = checkedDays / 7;
    String status;
    if (percentage >= 1.0) {
      status = '已完成';
    } else if (percentage >= 0.7) {
      status = '进行中';
    } else if (percentage > 0) {
      status = '刚开始';
    } else {
      status = '未开始';
    }

    // 使用图标
    final icon = Icons.calendar_today;

    return DotTrackerCardWidget(
      title: title,
      icon: icon,
      currentValue: checkedDays,
      unit: '/7 天',
      status: status,
      weekDays: weekDays,
      dotStates: dotStates,
      enableAnimation: true,
    );
  }
}
