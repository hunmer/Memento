import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 任务项数据模型
class TaskItem {
  final String title;
  final Color color;

  const TaskItem({
    required this.title,
    required this.color,
  });

  /// 从 JSON 创建（用于公共小组件系统）
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      title: json['title'] as String? ?? '',
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON（用于公共小组件系统）
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'color': color.value,
    };
  }
}

/// 即将到来的任务小组件
class UpcomingTasksWidget extends StatefulWidget {
  final int taskCount;
  final List<TaskItem> tasks;
  final int moreCount;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 小组件尺寸
  final HomeWidgetSize size;

  const UpcomingTasksWidget({
    super.key,
    required this.taskCount,
    required this.tasks,
    this.moreCount = 0,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory UpcomingTasksWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final tasksList = (props['tasks'] as List<dynamic>?)
            ?.map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return UpcomingTasksWidget(
      taskCount: props['taskCount'] as int? ?? 0,
      tasks: tasksList,
      moreCount: props['moreCount'] as int? ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<UpcomingTasksWidget> createState() => _UpcomingTasksWidgetState();
}

class _UpcomingTasksWidgetState extends State<UpcomingTasksWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.inline ? double.maxFinite : 400,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: widget.size.getPadding(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：任务计数
                  _buildTaskCounter(isDark),
                  SizedBox(width: widget.size.getTitleSpacing()),
                  // 右侧：任务列表
                  Expanded(
                    child: _buildTaskList(isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建任务计数区域
  Widget _buildTaskCounter(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 添加顶部 padding 以与右侧对齐
        SizedBox(height: widget.size.getItemSpacing()),
        AnimatedFlipCounter(
          value: widget.taskCount.toDouble() * _animation.value,
          textStyle: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
            height: 1.0,
          ),
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        SizedBox(
          width: 64,
          child: Text(
            'Upcoming tasks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建任务列表
  Widget _buildTaskList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(widget.tasks.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < widget.tasks.length - 1 ? widget.size.getItemSpacing() : 0),
            child: _TaskItemWidget(
              task: widget.tasks[index],
              isDark: isDark,
              animation: _animation,
              index: index,
              size: widget.size,
            ),
          );
        }),
        if (widget.moreCount > 0) ...[
          SizedBox(height: widget.size.getItemSpacing()),
          GestureDetector(
            onTap: () {
              // 处理"查看更多"点击
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('查看更多 ${widget.moreCount} 个任务'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              '+${widget.moreCount} more',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 单个任务项组件
class _TaskItemWidget extends StatelessWidget {
  final TaskItem task;
  final bool isDark;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _TaskItemWidget({
    required this.task,
    required this.isDark,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final itemAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * 0.1,
            0.5 + index * 0.1,
            curve: Curves.easeOutCubic,
          ),
        );

        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(10 * (1 - itemAnimation.value), 0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('点击任务: ${task.title}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // 彩色指示条
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: task.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: size.getItemSpacing()),
                    // 任务标题
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14.4, // 0.9rem ≈ 14.4px
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
