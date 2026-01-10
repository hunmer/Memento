import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

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
            icon: Icons.format_list_bulleted,
            iconBackgroundColor: Color(0xFF5A72EA),
            count: 48,
            countLabel: 'Upcoming',
            items: [
              'Design mobile UI dashboard',
              'Calculate budget and contract',
              'Search for a UI kit',
              'Create HTML & CSS for startup',
            ],
            moreCount: 10,
          ),
        ),
      ),
    );
  }
}

/// 任务列表数据模型
class TaskListItem {
  final String title;

  const TaskListItem({
    required this.title,
  });
}

/// 任务列表卡片小组件
class TaskListCardWidget extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 图标背景颜色
  final Color iconBackgroundColor;

  /// 任务总数
  final int count;

  /// 计数标签
  final String countLabel;

  /// 任务项列表
  final List<String> items;

  /// 更多任务数量
  final int moreCount;

  const TaskListCardWidget({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.count,
    required this.countLabel,
    required this.items,
    required this.moreCount,
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
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：图标和计数
                    _buildLeftSection(
                      context,
                      isDark,
                      textColor,
                      subtitleColor,
                    ),
                    const SizedBox(width: 24),
                    // 右侧：任务列表
                    Expanded(
                      child: _buildRightSection(
                        context,
                        isDark,
                        textColor,
                        borderColor,
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

  Widget _buildLeftSection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.iconBackgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.iconBackgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // 计数
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 56,
                child: AnimatedFlipCounter(
                  value: widget.count.toDouble() * _animation.value,
                  textStyle: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 18,
                child: Text(
                  widget.countLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务列表
        for (int i = 0; i < widget.items.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: borderColor,
            ),
          _TaskItemWidget(
            title: widget.items[i],
            animation: _animation,
            index: i,
            textColor: textColor,
          ),
        ],
        const SizedBox(height: 8),
        // 更多任务链接
        _MoreLinkWidget(
          count: widget.moreCount,
          animation: _animation,
          index: widget.items.length,
          color: widget.iconBackgroundColor,
        ),
      ],
    );
  }
}

/// 任务项组件
class _TaskItemWidget extends StatelessWidget {
  final String title;
  final Animation<double> animation;
  final int index;
  final Color textColor;

  const _TaskItemWidget({
    required this.title,
    required this.animation,
    required this.index,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.1,
        0.4 + index * 0.1,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 更多任务链接组件
class _MoreLinkWidget extends StatelessWidget {
  final int count;
  final Animation<double> animation;
  final int index;
  final Color color;

  const _MoreLinkWidget({
    required this.count,
    required this.animation,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final linkAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.1,
        0.4 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: linkAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: linkAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - linkAnimation.value)),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+$count more',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
