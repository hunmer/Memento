import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 活动进度小组件
class ActivityProgressCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final double value;
  final String unit;
  final int activities;
  final int totalProgress;
  final int completedProgress;

  const ActivityProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.activities,
    required this.totalProgress,
    required this.completedProgress,
  });

  /// 从 props 创建实例
  factory ActivityProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ActivityProgressCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      activities: props['activities'] as int? ?? 0,
      totalProgress: props['totalProgress'] as int? ?? 0,
      completedProgress: props['completedProgress'] as int? ?? 0,
    );
  }

  @override
  State<ActivityProgressCardWidget> createState() =>
      _ActivityProgressCardWidgetState();
}

class _ActivityProgressCardWidgetState extends State<ActivityProgressCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题和图标
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : Colors.grey.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle.isNotEmpty)
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_run,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 数值和活动数
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AnimatedFlipCounter(
                        value: widget.value * _animation.value,
                        fractionDigits: 1,
                        textStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (widget.activities > 0)
                      Text(
                        '${widget.activities} 活动',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // 进度点
                _ProgressDots(
                  total: widget.totalProgress,
                  completed: widget.completedProgress,
                  color: primaryColor,
                  animation: _animation,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 进度点组件
class _ProgressDots extends StatelessWidget {
  final int total;
  final int completed;
  final Color color;
  final Animation<double> animation;

  const _ProgressDots({
    required this.total,
    required this.completed,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final isCompleted = index < completed;
        final dotAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * 0.05,
            0.5 + index * 0.05,
            curve: Curves.easeOutCubic,
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: AnimatedBuilder(
            animation: dotAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: dotAnimation.value,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * dotAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? color
                          : color.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
