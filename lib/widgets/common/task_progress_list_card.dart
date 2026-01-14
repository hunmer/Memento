import 'package:flutter/material.dart';

/// 任务状态枚举
///
/// 表示任务当前所处的状态，用于显示不同颜色的进度条。
enum TaskStatus {
  /// 已完成（绿色）
  completed,

  /// 进行中（琥珀色）
  inProgress,

  /// 刚开始（玫瑰色）
  started,
}

/// 任务数据模型
///
/// 表示单个任务的信息，包含标题、时间、进度和状态。
/// 支持从 JSON 创建和转换为 JSON，便于数据持久化。
class TaskItem {
  /// 任务标题
  final String title;

  /// 任务时间描述（如 "24 分钟前"）
  final String time;

  /// 任务进度（0.0 - 1.0）
  final double progress;

  /// 任务状态
  final TaskStatus status;

  const TaskItem({
    required this.title,
    required this.time,
    required this.progress,
    required this.status,
  });

  /// 从 JSON 创建
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.started,
      ),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'progress': progress,
      'status': status.name,
    };
  }
}

/// 任务进度列表卡片组件
///
/// 显示一组任务的进度列表，每项包含任务标题、时间和进度条。
/// 根据任务状态显示不同颜色的进度条（已完成、进行中、刚开始）。
///
/// 特性：
/// - 入场淡入和位移动画
/// - 任务项交错动画
/// - 进度条动画
/// - 深色模式适配
/// - 可选的"更多"链接
/// - 可自定义标题和图标
///
/// 示例用法：
/// ```dart
/// TaskProgressListCard(
///   title: '进度',
///   icon: Icons.check_circle_outline,
///   tasks: [
///     TaskItem(
///       title: '设计移动端 UI 仪表板',
///       time: '24 分钟前',
///       progress: 1.0,
///       status: TaskStatus.completed,
///     ),
///     TaskItem(
///       title: '计算预算和合同',
///       time: '54 分钟前',
///       progress: 0.67,
///       status: TaskStatus.inProgress,
///     ),
///   ],
///   moreCount: 10,
///   onMoreTap: () {
///     print('查看更多');
///   },
///   onTaskTap: (index, task) {
///     print('点击任务 $index: ${task.title}');
///   },
/// )
/// ```
class TaskProgressListCard extends StatefulWidget {
  /// 卡片标题（默认为 "进度"）
  final String title;

  /// 标题图标（默认为 Icons.check_circle_outline）
  final IconData? icon;

  /// 任务列表
  final List<TaskItem> tasks;

  /// 更多任务数量
  final int moreCount;

  /// 卡片宽度（默认为 312）
  final double? width;

  /// 更多链接点击回调
  final VoidCallback? onMoreTap;

  /// 任务项点击回调
  final ValueChanged<int>? onTaskTap;

  const TaskProgressListCard({
    super.key,
    this.title = '进度',
    this.icon,
    required this.tasks,
    this.moreCount = 0,
    this.width,
    this.onMoreTap,
    this.onTaskTap,
  });

  @override
  State<TaskProgressListCard> createState() => _TaskProgressListCardState();
}

class _TaskProgressListCardState extends State<TaskProgressListCard>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.width ?? 312,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题区域
                  _buildHeader(context, isDark),
                  const SizedBox(height: 24),

                  // 任务列表
                  ..._buildTaskList(context, isDark),

                  // 底部更多链接
                  if (widget.moreCount > 0) ...[
                    const SizedBox(height: 8),
                    _buildMoreLink(context, isDark),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题区域
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Icon(
          widget.icon ?? Icons.check_circle_outline,
          size: 20,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// 构建任务列表
  List<Widget> _buildTaskList(BuildContext context, bool isDark) {
    final List<Widget> widgets = [];

    for (int i = 0; i < widget.tasks.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 20));
      }

      // 计算每个任务的动画延迟，确保 end 不超过 1.0
      final end = (0.6 + i * 0.12).clamp(0.0, 1.0);
      final itemAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          i * 0.12,
          end,
          curve: Curves.easeOutCubic,
        ),
      );

      widgets.add(_TaskItemWidget(
        task: widget.tasks[i],
        animation: itemAnimation,
        isDark: isDark,
        isLast: i == widget.tasks.length - 1,
        onTap: widget.onTaskTap != null ? () => widget.onTaskTap!(i) : null,
      ));
    }

    return widgets;
  }

  /// 构建更多链接
  Widget _buildMoreLink(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: widget.onMoreTap,
        child: Text(
          '+${widget.moreCount} 更多',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// 任务项小组件（私有）
class _TaskItemWidget extends StatelessWidget {
  final TaskItem task;
  final Animation<double> animation;
  final bool isDark;
  final bool isLast;
  final VoidCallback? onTap;

  const _TaskItemWidget({
    required this.task,
    required this.animation,
    required this.isDark,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    // 左侧：标题和时间
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
                              color: isDark
                                  ? const Color(0xFFF9FAFB)
                                  : const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 右侧：进度条
                    _ProgressBarWidget(
                      progress: task.progress,
                      status: task.status,
                      animation: animation,
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

/// 进度条小组件（私有）
class _ProgressBarWidget extends StatelessWidget {
  final double progress;
  final TaskStatus status;
  final Animation<double> animation;

  const _ProgressBarWidget({
    required this.progress,
    required this.status,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 根据状态获取颜色
    Color getProgressColor() {
      switch (status) {
        case TaskStatus.completed:
          return const Color(0xFF34D399); // Emerald 400
        case TaskStatus.inProgress:
          return const Color(0xFFFBBF24); // Amber 400
        case TaskStatus.started:
          return const Color(0xFFFB7185); // Rose 400
      }
    }

    final progressColor = getProgressColor();
    final backgroundColor =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6);

    return Container(
      width: 48,
      height: 6,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: progress * animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
