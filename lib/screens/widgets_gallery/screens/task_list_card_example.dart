import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 任务列表卡片示例
class TaskListCardExample extends StatelessWidget {
  const TaskListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TaskListCardWidget(
            taskCount: 18,
            tasks: [
              TaskItem(title: 'Pick up arts & crafts supplies'),
              TaskItem(title: 'Send cookie recipe to mom'),
              TaskItem(title: 'Book club prep'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 任务数据模型
class TaskItem {
  final String title;
  final bool isCompleted;

  const TaskItem({
    required this.title,
    this.isCompleted = false,
  });
}

/// 任务列表卡片小组件
class TaskListCardWidget extends StatefulWidget {
  final int taskCount;
  final List<TaskItem> tasks;

  const TaskListCardWidget({
    super.key,
    required this.taskCount,
    required this.tasks,
  });

  @override
  State<TaskListCardWidget> createState() => _TaskListCardWidgetState();
}

class _TaskListCardWidgetState extends State<TaskListCardWidget>
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
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: _buildCard(isDark),
    );
  }

  Widget _buildCard(bool isDark) {
    // 使用主题颜色系统
    final primaryColor = Theme.of(context).colorScheme.error; // iOS Red
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade100 : Colors.grey.shade900;
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final checkboxBorder = isDark ? Colors.grey.shade500 : Colors.grey.shade300;

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(primaryColor, textColor, isDark),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildTaskList(checkboxBorder, borderColor, subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, Color textColor, bool isDark) {
    final countAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders',
          style: TextStyle(
            color: primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(
          height: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 32,
                child: AnimatedFlipCounter(
                  value: widget.taskCount * countAnimation.value,
                  textStyle: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(Color checkboxBorder, Color borderColor, Color subtitleColor) {
    final displayTasks = widget.tasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < displayTasks.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _TaskItemWidget(
            task: displayTasks[i],
            checkboxBorder: checkboxBorder,
            borderColor: borderColor,
            textColor: subtitleColor,
            animation: _animation,
            index: i,
            showDivider: i < displayTasks.length - 1,
          ),
        ],
      ],
    );
  }
}

/// 单个任务项组件
class _TaskItemWidget extends StatelessWidget {
  final TaskItem task;
  final Color checkboxBorder;
  final Color borderColor;
  final Color textColor;
  final Animation<double> animation;
  final int index;
  final bool showDivider;

  const _TaskItemWidget({
    required this.task,
    required this.checkboxBorder,
    required this.borderColor,
    required this.textColor,
    required this.animation,
    required this.index,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.15,
        0.6 + index * 0.15,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圆形复选框
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: checkboxBorder,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 任务文本和分隔线
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showDivider) ...[
                  const SizedBox(height: 10),
                  _DottedLine(color: borderColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 虚线分隔线组件
class _DottedLine extends StatelessWidget {
  final Color color;

  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1.5),
      painter: _DottedLinePainter(color: color),
    );
  }
}

/// 虚线绘制器
class _DottedLinePainter extends CustomPainter {
  final Color color;

  const _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
