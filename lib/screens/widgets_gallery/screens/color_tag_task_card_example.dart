import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 彩色标签任务列表卡片示例
class ColorTagTaskCardExample extends StatelessWidget {
  const ColorTagTaskCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('彩色标签任务列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: ColorTagTaskCardWidget(
            taskCount: 56,
            label: 'Upcoming tasks',
            tasks: [
              ColorTagTaskItem(
                title: 'Design mobile UI dashboard for iOS',
                color: Color(0xFF3B82F6),
              ),
              ColorTagTaskItem(
                title: 'Calculate budget and contract',
                color: Color(0xFFFB7185),
              ),
              ColorTagTaskItem(
                title: 'Search for a UI kit',
                color: Color(0xFFFBBF24),
              ),
              ColorTagTaskItem(
                title: 'Create HTML & CSS for startup',
                color: Color(0xFF3B82F6),
              ),
              ColorTagTaskItem(
                title: 'Design search page for website',
                color: Color(0xFF34D399),
              ),
              ColorTagTaskItem(
                title: 'Send an estimate budget for app',
                color: Color(0xFFFB7185),
              ),
              ColorTagTaskItem(
                title: 'Search for a mobile UI kit',
                color: Color(0xFFFBBF24),
              ),
              ColorTagTaskItem(
                title: 'Export assets for HTML developer',
                color: Color(0xFF3B82F6),
              ),
            ],
            moreCount: 10,
          ),
        ),
      ),
    );
  }
}

/// 彩色标签任务数据模型
class ColorTagTaskItem {
  final String title;
  final Color color;

  const ColorTagTaskItem({
    required this.title,
    required this.color,
  });
}

/// 彩色标签任务列表卡片小组件
class ColorTagTaskCardWidget extends StatefulWidget {
  final int taskCount;
  final String label;
  final List<ColorTagTaskItem> tasks;
  final int moreCount;

  const ColorTagTaskCardWidget({
    super.key,
    required this.taskCount,
    required this.label,
    required this.tasks,
    this.moreCount = 0,
  });

  @override
  State<ColorTagTaskCardWidget> createState() => _ColorTagTaskCardWidgetState();
}

class _ColorTagTaskCardWidgetState extends State<ColorTagTaskCardWidget>
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
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF);
    final primaryColor = Theme.of(context).colorScheme.primary;

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
      child: Container(
        width: 360,
        height: 380,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              _buildHeader(textColor, secondaryTextColor, primaryColor),
              const SizedBox(height: 16),
              // 任务列表
              Expanded(
                child: _buildTaskList(),
              ),
              // 底部更多按钮
              if (widget.moreCount > 0) _buildMoreButton(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor, Color primaryColor) {
    final countAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 52,
                child: AnimatedFlipCounter(
                  value: widget.taskCount * countAnimation.value,
                  textStyle: TextStyle(
                    color: textColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 20,
          child: Text(
            widget.label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _ColorTagTaskItemWidget(
              task: widget.tasks[i],
              animation: _animation,
              index: i,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreButton(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: () {},
        child: Text(
          '+${widget.moreCount} more',
          style: TextStyle(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 彩色标签任务项组件
class _ColorTagTaskItemWidget extends StatelessWidget {
  final ColorTagTaskItem task;
  final Animation<double> animation;
  final int index;

  const _ColorTagTaskItemWidget({
    required this.task,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

    // 确保最后一个元素的 end 不超过 1.0
    final step = 0.05;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * step,
        0.6 + index * step,
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
      child: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            // 彩色竖条标签
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 任务标题
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
