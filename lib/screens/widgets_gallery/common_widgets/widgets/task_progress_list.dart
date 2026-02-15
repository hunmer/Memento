import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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

  factory TaskProgressData.fromJson(Map<String, dynamic> json) {
    return TaskProgressData(
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'progress': progress,
      'color': color.value,
    };
  }
}

/// 任务进度列表小组件
class TaskProgressListWidget extends StatefulWidget {
  final List<TaskProgressData> tasks;
  final int moreCount;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const TaskProgressListWidget({
    super.key,
    required this.tasks,
    this.moreCount = 0,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory TaskProgressListWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final tasksList = (props['tasks'] as List<dynamic>?)
            ?.map((e) => TaskProgressData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return TaskProgressListWidget(
      tasks: tasksList,
      moreCount: props['moreCount'] as int? ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
              width: widget.inline ? double.maxFinite : 360,
              padding: widget.size.getPadding(),
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
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 任务列表 - 添加滚动支持
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                              size: widget.size,
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
  final HomeWidgetSize size;

  const _TaskProgressItem({
    required this.task,
    required this.animation,
    required this.index,
    required this.isLast,
    required this.textMainColor,
    required this.textSubColor,
    required this.borderColor,
    required this.progressBgColor,
    required this.size,
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
          SizedBox(height: size.getItemSpacing()),
          Container(
            height: 1,
            color: borderColor,
          ),
          SizedBox(height: size.getItemSpacing()),
        ],
      ],
    );
  }
}
