/// 积分目标进度公共小组件
///
/// 显示今日积分与目标的进度
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 积分目标进度小组件
class PointsGoalCardWidget extends StatefulWidget {
  /// 今日积分
  final int todayPoints;

  /// 目标积分
  final int goal;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const PointsGoalCardWidget({
    super.key,
    required this.todayPoints,
    required this.goal,
    required this.size,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory PointsGoalCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return PointsGoalCardWidget(
      todayPoints: (props['todayPoints'] as num?)?.toInt() ?? 0,
      goal: (props['goal'] as num?)?.toInt() ?? 100,
      size: size,
    );
  }

  @override
  State<PointsGoalCardWidget> createState() =>
      _PointsGoalCardWidgetState();
}

class _PointsGoalCardWidgetState extends State<PointsGoalCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        widget.goal > 0 ? (widget.todayPoints / widget.goal).clamp(0.0, 1.0) : 0.0;
    final isCompleted = widget.todayPoints >= widget.goal;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.emoji_events : Icons.flag,
                  color: Colors.black,
                  size: widget.size.isCardSized ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日积分目标',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  Icon(Icons.check_circle, color: Colors.black, size: widget.size.isCardSized ? 24 : 20),
              ],
            ),
            const SizedBox(height: 8),

            // 高进度条+文字内嵌显示
            Stack(
              children: [
                // 背景条
                Container(
                  height: widget.size.isCardSized ? 56 : 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // 进度填充
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: widget.size.isCardSized ? 56 : 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // 文字内嵌在进度条中
                SizedBox(
                  height: widget.size.isCardSized ? 56 : 48,
                  child: Center(
                    child: Text(
                      '${widget.todayPoints} / ${widget.goal}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
