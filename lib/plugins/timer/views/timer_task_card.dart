import 'package:flutter/material.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/plugins/timer/views/timer_task_card_adapter.dart';

/// TimerTaskCard - 计时器任务卡片
///
/// 适配器类，使用公共小组件系统中的 TimerCardWidget
/// 保持原有 API 兼容性
class TimerTaskCard extends StatelessWidget {
  final TimerTask task;
  final Function(TimerTask) onTap;
  final Function(TimerTask) onEdit;
  final Function(TimerTask) onReset;
  final Function(TimerTask) onDelete;

  const TimerTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onReset,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TimerTaskCardAdapter(
      task: task,
      onTap: onTap,
      onEdit: onEdit,
      onReset: onReset,
      onDelete: onDelete,
    );
  }
}
