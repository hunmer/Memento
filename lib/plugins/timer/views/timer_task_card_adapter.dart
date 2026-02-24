import 'package:flutter/material.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/widgets/common/timer_card_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// TimerTaskCard 适配器
///
/// 将原有的 TimerTaskCard 组件适配为使用新的 Command Widget
class TimerTaskCardAdapter extends StatelessWidget {
  final TimerTask task;
  final Function(TimerTask)? onTap;
  final Function(TimerTask)? onEdit;
  final Function(TimerTask)? onReset;
  final Function(TimerTask)? onDelete;
  final double? width;
  final double? height;

  const TimerTaskCardAdapter({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onReset,
    this.onDelete,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return TimerCardWidget(
      task: task,
      onTap: onTap,
      onEdit: onEdit,
      onReset: onReset,
      onDelete: onDelete,
      borderColor: task.color,
      backgroundColor: Colors.transparent,
      textColor: null,
      showActionButtons: true,
      size: _createSize(width, height),
    );
  }

  /// 创建基于尺寸的 HomeWidgetSize
  HomeWidgetSize _createSize(double? width, double? height) {
    // 这里可以根据实际尺寸需求创建不同的 HomeWidgetSize
    // 目前使用默认的 LargeSize
    return const LargeSize();
  }
}