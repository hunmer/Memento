import 'package:flutter/material.dart';

/// 圆角任务列表卡片示例
class RoundedTaskListCardExample extends StatelessWidget {
  const RoundedTaskListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角任务列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: RoundedTaskListCardWidget(
            tasks: [
              TaskItem(
                title: 'Design mobile UI dashboard',
                subtitle: 'Widgefy UI kit',
                date: '12 Jan 2021',
              ),
              TaskItem(
                title: 'Calculate budget and contract',
                subtitle: 'BetaCRM',
                date: '1 Feb 2021',
              ),
              TaskItem(
                title: 'Search for a UI kit',
                subtitle: 'Cardify landing pack',
                date: '9 Mar 2021',
              ),
              TaskItem(
                title: 'Design search page for website',
                subtitle: 'IOTask UI kit',
                date: '10 Feb 2021',
              ),
              TaskItem(
                title: 'Create HTML & CSS for startup',
                subtitle: 'Roomsfy',
                date: '21 Feb 2021',
              ),
            ],
            headerText: 'Upcoming',
          ),
        ),
      ),
    );
  }
}

/// 任务项数据模型
class TaskItem {
  final String title;
  final String subtitle;
  final String date;

  const TaskItem({
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

/// 圆角任务列表卡片小组件
class RoundedTaskListCardWidget extends StatefulWidget {
  final List<TaskItem> tasks;
  final String headerText;

  const RoundedTaskListCardWidget({
    super.key,
    required this.tasks,
    this.headerText = 'Upcoming',
  });

  @override
  State<RoundedTaskListCardWidget> createState() => _RoundedTaskListCardWidgetState();
}

class _RoundedTaskListCardWidgetState extends State<RoundedTaskListCardWidget>
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
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, primaryColor, subtextColor),
                  const SizedBox(height: 24),
                  // 任务列表
                  ..._buildTaskList(context, primaryColor, subtextColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
  final TaskItem task;
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
              padding: const EdgeInsets.symmetric(vertical: 16),
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
