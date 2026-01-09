import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 习惯连续打卡追踪器示例
class HabitStreakTrackerExample extends StatelessWidget {
  const HabitStreakTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('习惯连续打卡追踪器')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
        child: const Center(
          child: HabitStreakTrackerWidget(
            currentStreak: 5,
            longestStreak: 15,
            totalDays: 10,
            completedDays: [1, 2, 3, 4, 5],
          ),
        ),
      ),
    );
  }
}

/// 习惯连续打卡追踪小组件
class HabitStreakTrackerWidget extends StatefulWidget {
  /// 当前连续天数
  final int currentStreak;

  /// 最长连续天数
  final int longestStreak;

  /// 总天数
  final int totalDays;

  /// 已完成的天数列表
  final List<int> completedDays;

  const HabitStreakTrackerWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    required this.completedDays,
  });

  @override
  State<HabitStreakTrackerWidget> createState() =>
      _HabitStreakTrackerWidgetState();
}

class _HabitStreakTrackerWidgetState extends State<HabitStreakTrackerWidget>
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
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final primaryColor = const Color(0xFF3f51b5);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前连续打卡
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Streak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedFlipCounter(
                value: widget.currentStreak * _animation.value,
                suffix: ' Days',
                textStyle: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 分隔线
          Container(
            height: 2,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 最长连续打卡
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Longest Streak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                '${widget.longestStreak} days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 日期网格
          _buildDaysGrid(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(bool isDark, Color primaryColor) {
    // 计算延迟步长，确保 Interval end <= 1.0
    final elementCount = widget.totalDays;
    final baseEnd = 0.6;
    final maxStep = (1.0 - baseEnd) / (elementCount - 1);
    final step = maxStep * 0.8; // 留安全余量

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: widget.totalDays,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final isCompleted = widget.completedDays.contains(dayNumber);
        final isCurrent = dayNumber <= widget.currentStreak;

        // 计算每个元素的延迟动画
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * step,
            baseEnd + index * step,
            curve: Curves.easeOutCubic,
          ),
        );

        return _DayItem(
          dayNumber: dayNumber,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          primaryColor: primaryColor,
          isDark: isDark,
          animation: itemAnimation,
        );
      },
    );
  }
}

/// 日期单项组件
class _DayItem extends StatelessWidget {
  final int dayNumber;
  final bool isCompleted;
  final bool isCurrent;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;

  const _DayItem({
    required this.dayNumber,
    required this.isCompleted,
    required this.isCurrent,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (isCurrent && isCompleted) {
      // 已完成 - 实心圆
      return Container(
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      );
    } else if (isCompleted) {
      // 已完成但不在当前连续中
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              Icons.check_circle,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade300,
              size: 18,
            ),
          ],
        ),
      );
    } else {
      // 未完成 - 虚线边框
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              Icons.check_circle,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              size: 18,
            ),
          ],
        ),
      );
    }
  }
}
