import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 睡眠追踪卡片示例
class SleepTrackingCardExample extends StatelessWidget {
  const SleepTrackingCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SleepTrackingCardWidget(
            sleepHours: 3.57,
            sleepLabel: 'Insomniac',
            weeklyProgress: [
              WeekDayData(day: 'M', achieved: true, progress: 1.0),
              WeekDayData(day: 'T', achieved: false, progress: 0.68),
              WeekDayData(day: 'W', achieved: true, progress: 1.0),
              WeekDayData(day: 'T', achieved: true, progress: 0.92),
              WeekDayData(day: 'F', achieved: false, progress: 0.6),
              WeekDayData(day: 'S', achieved: false, progress: 0.76),
              WeekDayData(day: 'S', achieved: true, progress: 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// 周数据模型
class WeekDayData {
  final String day;
  final bool achieved;
  final double progress;

  const WeekDayData({
    required this.day,
    required this.achieved,
    required this.progress,
  });
}

/// 睡眠追踪卡片小组件
class SleepTrackingCardWidget extends StatefulWidget {
  final double sleepHours;
  final String sleepLabel;
  final List<WeekDayData> weeklyProgress;

  const SleepTrackingCardWidget({
    super.key,
    required this.sleepHours,
    required this.sleepLabel,
    required this.weeklyProgress,
  });

  @override
  State<SleepTrackingCardWidget> createState() =>
      _SleepTrackingCardWidgetState();
}

class _SleepTrackingCardWidgetState extends State<SleepTrackingCardWidget>
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
    final primaryColor =
        isDark
            ? const Color(0xFFF36E24)
            : Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow:
                    isDark
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, isDark, primaryColor),
                  const SizedBox(height: 24),
                  // 主内容区
                  _buildContent(context, isDark, primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.bedtime_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Sleep',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            // TODO: 处理点击事件
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color:
                      isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 左侧：睡眠时长
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: AnimatedFlipCounter(
                      value: widget.sleepHours * _animation.value,
                      fractionDigits: 2,
                      textStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    child: Text(
                      'hr',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.sleepLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        // 右侧：周日程进度
        Row(
          children:
              widget.weeklyProgress.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;

                // 计算动画延迟
                final itemAnimation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.08,
                    0.5 + index * 0.08,
                    curve: Curves.easeOutCubic,
                  ),
                );

                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                  child: _WeekDayIndicator(
                    day: data.day,
                    achieved: data.achieved,
                    progress: data.progress,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    animation: itemAnimation,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

/// 周日进度指示器
class _WeekDayIndicator extends StatelessWidget {
  final String day;
  final bool achieved;
  final double progress;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;

  const _WeekDayIndicator({
    required this.day,
    required this.achieved,
    required this.progress,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedProgress = progress * animation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achieved ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color:
                  achieved
                      ? (isDark ? Colors.white : const Color(0xFF111827))
                      : (isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _CircleProgressPainter(
                  progress: animatedProgress,
                  primaryColor: primaryColor,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 圆形进度绘制器
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  _CircleProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5; // 减去描边宽度的一半
    final strokeWidth = 2.5;

    // 绘制背景圆环
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆弧
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      const startAngle = -3.141592653589793238 / 2; // 从顶部开始
      final sweepAngle = 2 * 3.141592653589793238 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
