import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 任务进度列表示例
class TaskProgressListExample extends StatelessWidget {
  const TaskProgressListExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务进度列表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TaskProgressListWidget(
            tasks: [
              TaskProgressData(
                title: 'Design mobile UI dashboard',
                time: '24 mins ago',
                progress: 1.0,
                color: Color(0xFF34D399),
              ),
              TaskProgressData(
                title: 'Calculate budget and contract',
                time: '54 mins ago',
                progress: 0.67,
                color: Color(0xFFFBBF24),
              ),
              TaskProgressData(
                title: 'Search for a UI kit',
                time: '54 mins ago',
                progress: 1.0,
                color: Color(0xFF34D399),
              ),
              TaskProgressData(
                title: 'Design search page for website',
                time: '54 mins ago',
                progress: 0.25,
                color: Color(0xFFFB7185),
              ),
              TaskProgressData(
                title: 'Create HTML & CSS for startup',
                time: '54 mins ago',
                progress: 0.25,
                color: Color(0xFFFB7185),
              ),
            ],
            moreCount: 10,
          ),
        ),
      ),
    );
  }
}

/// 任务进度数据模型
class TaskProgressData {
  final String title;
  final String time;
  final double progress;
  final Color color;

  const TaskProgressData({
    required this.title,
    required this.time,
    required this.progress,
    required this.color,
  });
}

/// 任务进度列表小组件
class TaskProgressListWidget extends StatefulWidget {
  final List<TaskProgressData> tasks;
  final int moreCount;

  const TaskProgressListWidget({
    super.key,
    required this.tasks,
    this.moreCount = 0,
  });

  @override
  State<TaskProgressListWidget> createState() => _TaskProgressListWidgetState();
}

class _TaskProgressListWidgetState extends State<TaskProgressListWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textMainColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final textSubColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final progressBgColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: textSubColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: textSubColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 任务列表
                  ...List.generate(
                    widget.tasks.length,
                    (index) => _TaskProgressItem(
                      task: widget.tasks[index],
                      animation: _animation,
                      index: index,
                      isLast: index == widget.tasks.length - 1,
                      textMainColor: textMainColor,
                      textSubColor: textSubColor,
                      borderColor: borderColor,
                      progressBgColor: progressBgColor,
                    ),
                  ),
                  // 更多链接
                  if (widget.moreCount > 0) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '+${widget.moreCount} more',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 任务进度项组件
class _TaskProgressItem extends StatelessWidget {
  final TaskProgressData task;
  final Animation<double> animation;
  final int index;
  final bool isLast;
  final Color textMainColor;
  final Color textSubColor;
  final Color borderColor;
  final Color progressBgColor;

  const _TaskProgressItem({
    required this.task,
    required this.animation,
    required this.index,
    required this.isLast,
    required this.textMainColor,
    required this.textSubColor,
    required this.borderColor,
    required this.progressBgColor,
  });

  @override
  Widget build(BuildContext context) {
    // 计算每个元素的延迟动画
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.12,
        0.6 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    final clampedProgress = (itemAnimation.value * task.progress).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: itemAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: itemAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - itemAnimation.value)),
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: textMainColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 16,
                            child: Text(
                              task.time,
                              style: TextStyle(
                                color: textSubColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 进度条
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: progressBgColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 48 * clampedProgress,
                            height: 6,
                            decoration: BoxDecoration(
                              color: task.color,
                              boxShadow: [
                                BoxShadow(
                                  color: task.color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (!isLast) ...[
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: borderColor,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
