import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 任务进度卡片小组件
class TaskProgressCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int completedTasks;
  final int totalTasks;
  final List<String> pendingTasks;

  const TaskProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completedTasks,
    required this.totalTasks,
    this.pendingTasks = const [],
  });

  /// 从 props 创建实例
  factory TaskProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return TaskProgressCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      completedTasks: props['completedTasks'] as int? ?? 0,
      totalTasks: props['totalTasks'] as int? ?? 0,
      pendingTasks: (props['pendingTasks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  @override
  State<TaskProgressCardWidget> createState() =>
      _TaskProgressCardWidgetState();
}

class _TaskProgressCardWidgetState extends State<TaskProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final dividerColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final progressTrackColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题部分
                _buildHeaderSection(textColor, secondaryTextColor),

                const SizedBox(height: 16),

                // 进度条部分
                _buildProgressSection(progressTrackColor),

                if (widget.pendingTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // 待办任务列表
                  _buildPendingTasksSection(secondaryTextColor, dividerColor),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.subtitle.isNotEmpty)
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildProgressSection(Color progressTrackColor) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final progress =
        widget.totalTasks > 0 ? widget.completedTasks / widget.totalTasks : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '进度',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 16,
                  child: AnimatedFlipCounter(
                    value: widget.completedTasks * _animation.value,
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                const Text(' / ', style: TextStyle(fontSize: 12)),
                SizedBox(
                  width: 24,
                  height: 16,
                  child: AnimatedFlipCounter(
                    value: widget.totalTasks.toDouble(),
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: progressTrackColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress * _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTasksSection(
    Color secondaryTextColor,
    Color dividerColor,
  ) {
    final tasks = widget.pendingTasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '待办',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ),
        for (int i = 0; i < tasks.length; i++) ...[
          if (i > 0) Divider(color: dividerColor, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              tasks[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
