import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 任务列表项数据模型
class TaskListItem {
  /// 任务标题
  final String title;

  /// 任务副标题
  final String subtitle;

  /// 任务日期
  final String date;

  const TaskListItem({
    required this.title,
    required this.subtitle,
    required this.date,
  });

  /// 创建副本
  TaskListItem copyWith({
    String? title,
    String? subtitle,
    String? date,
  }) {
    return TaskListItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
    );
  }

  /// 从 JSON 创建
  factory TaskListItem.fromJson(Map<String, dynamic> json) {
    return TaskListItem(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      date: json['date'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'date': date,
    };
  }
}

/// 圆角任务列表卡片组件
///
/// 用于展示任务列表的高度圆角卡片组件，支持动画效果和主题适配。
/// 显示标题、任务列表和日期信息。
///
/// 使用示例：
/// ```dart
/// RoundedTaskListCard(
///   tasks: [
///     TaskListItem(
///       title: 'Design mobile UI dashboard',
///       subtitle: 'Widgefy UI kit',
///       date: '12 Jan 2021',
///     ),
///     TaskListItem(
///       title: 'Calculate budget and contract',
///       subtitle: 'BetaCRM',
///       date: '1 Feb 2021',
///     ),
///   ],
///   headerText: 'Upcoming',
/// )
/// ```
class RoundedTaskListCard extends StatefulWidget {
  /// 任务列表
  final List<TaskListItem> tasks;

  /// 标题文本
  final String headerText;

  const RoundedTaskListCard({
    super.key,
    required this.tasks,
    this.headerText = 'Upcoming',
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory RoundedTaskListCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final tasksList =
        (props['tasks'] as List<dynamic>?)
            ?.map((e) => TaskListItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return RoundedTaskListCard(
      tasks: tasksList,
      headerText: props['headerText'] as String? ?? 'Upcoming',
    );
  }

  @override
  State<RoundedTaskListCard> createState() => _RoundedTaskListCardState();
}

class _RoundedTaskListCardState extends State<RoundedTaskListCard>
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
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.tertiary;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: 344,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, primaryColor, subtextColor),
                  const SizedBox(height: 24),
                  // 任务列表 - 支持滚动
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildTaskList(
                          context,
                          primaryColor,
                          subtextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, Color primaryColor, Color subtextColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.headerText.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: subtextColor,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  /// 构建任务列表
  List<Widget> _buildTaskList(BuildContext context, Color primaryColor, Color subtextColor) {
    final widgets = <Widget>[];
    final elementCount = widget.tasks.length;
    const baseStart = 0.0;
    const baseEnd = 0.5;
    // 计算合适的 step 确保最后一个 Interval 的 end <= 1.0
    // step <= (1.0 - baseEnd) / (elementCount - 1)
    final step = elementCount > 1 ? (1.0 - baseEnd) / (elementCount - 1) * 0.9 : 0.1;

    for (int i = 0; i < widget.tasks.length; i++) {
      final task = widget.tasks[i];
      final itemAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          baseStart + i * step,
          baseEnd + i * step,
          curve: Curves.easeOutCubic,
        ),
      );

      widgets.add(
        _TaskListItem(
          task: task,
          animation: itemAnimation,
          primaryColor: primaryColor,
          subtextColor: subtextColor,
          isLast: i == widget.tasks.length - 1,
        ),
      );
    }

    return widgets;
  }
}

/// 任务列表项组件
class _TaskListItem extends StatelessWidget {
  final TaskListItem task;
  final Animation<double> animation;
  final Color primaryColor;
  final Color subtextColor;
  final bool isLast;

  const _TaskListItem({
    required this.task,
    required this.animation,
    required this.primaryColor,
    required this.subtextColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subtextColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    task.date,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
