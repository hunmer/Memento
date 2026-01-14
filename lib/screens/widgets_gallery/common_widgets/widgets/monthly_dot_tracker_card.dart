import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/dot_tracker_card.dart';

/// 月度点追踪卡片适配器
///
/// 包装 lib/widgets/common/dot_tracker_card.dart 中的 DotTrackerCardWidget
/// 使其符合公共小组件系统的接口规范
class MonthlyDotTrackerCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;
  final HomeWidgetSize size;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const MonthlyDotTrackerCardWidget({
    super.key,
    required this.props,
    required this.size,
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MonthlyDotTrackerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MonthlyDotTrackerCardWidget(
      props: props,
      size: size,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String? ?? '月度追踪';
    final currentValue = props['currentValue'] as int? ?? 0;
    final totalDays = props['totalDays'] as int? ?? 30;
    final iconCodePoint = props['iconCodePoint'] as int? ?? Icons.checklist.codePoint;
    final daysData = (props['daysData'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // 从 daysData 提取数据
    final weekDays = <String>[];
    final dotStates = <List<bool>>[];

    for (final dayData in daysData) {
      final day = dayData['day'] as int? ?? 1;
      final isChecked = dayData['isChecked'] as bool? ?? false;

      // 使用日期标签
      weekDays.add('$day');

      // 每天使用单个点状态
      dotStates.add([isChecked]);
    }

    // 如果 daysData 为空，使用默认当月天数
    if (weekDays.isEmpty) {
      for (int i = 1; i <= totalDays; i++) {
        weekDays.add('$i');
        dotStates.add([false]);
      }
    }

    // 计算状态文本
    final percentage = totalDays > 0 ? currentValue / totalDays : 0;
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

    // 使用传入的图标
    final icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');

    return DotTrackerCardWidget(
      title: title,
      icon: icon,
      currentValue: currentValue,
      unit: '/$totalDays 天',
      status: status,
      weekDays: weekDays,
      dotStates: dotStates,
      enableAnimation: true,
      inline: inline,
    );
  }
}
