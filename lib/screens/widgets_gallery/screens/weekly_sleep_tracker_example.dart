import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 睡眠追踪小组件示例
class WeeklySleepTrackerExample extends StatelessWidget {
  const WeeklySleepTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: WeeklySleepTrackerWidget(
            totalHours: 3.57,
            statusLabel: 'Insomniac',
            weeklyData: [
              DaySleepData(isCompleted: true, progress: 1.0, day: 'M'),
              DaySleepData(isCompleted: false, progress: 0.68, day: 'T'),
              DaySleepData(isCompleted: true, progress: 1.0, day: 'W'),
              DaySleepData(isCompleted: true, progress: 0.92, day: 'T'),
              DaySleepData(isCompleted: false, progress: 0.60, day: 'F'),
              DaySleepData(isCompleted: false, progress: 0.76, day: 'S'),
              DaySleepData(isCompleted: true, progress: 1.0, day: 'S'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 每日睡眠数据模型
class DaySleepData {
  final bool isCompleted;
  final double progress;
  final String day;

  const DaySleepData({
    required this.isCompleted,
    required this.progress,
    required this.day,
  });
}

/// 睡眠追踪小组件
class WeeklySleepTrackerWidget extends StatefulWidget {
  final double totalHours;
  final String statusLabel;
  final List<DaySleepData> weeklyData;

  const WeeklySleepTrackerWidget({
    super.key,
    required this.totalHours,
    required this.statusLabel,
    required this.weeklyData,
  });

  @override
  State<WeeklySleepTrackerWidget> createState() =>
      _WeeklySleepTrackerWidgetState();
}

class _WeeklySleepTrackerWidgetState extends State<WeeklySleepTrackerWidget>
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
    final backgroundColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final primaryColor = const Color(0xFFF36E24);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.bedtime_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sleep',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: 导航到详情页
                        },
                        child: Row(
                          children: [
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: secondaryTextColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 睡眠时长和状态
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 54,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 48,
                                  child: AnimatedFlipCounter(
                                    value: widget.totalHours * _animation.value,
                                    fractionDigits:
                                        widget.totalHours % 1 != 0 ? 2 : 0,
                                    textStyle: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.statusLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),

                      // 7天进度环
                      Row(
                        children: List.generate(widget.weeklyData.length, (
                          index,
                        ) {
                          final dayData = widget.weeklyData[index];
                          final itemAnimation = CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.12,
                              0.6 + index * 0.12,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return Padding(
                            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                            child: _DayProgressRing(
                              data: dayData,
                              primaryColor: primaryColor,
                              isDark: isDark,
                              animation: itemAnimation,
                            ),
                          );
                        }),
                      ),
                    ],
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

/// 单日进度环组件
class _DayProgressRing extends StatelessWidget {
  final DaySleepData data;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;

  const _DayProgressRing({
    required this.data,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        data.isCompleted
            ? (isDark ? Colors.white : const Color(0xFF111827))
            : (isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          data.isCompleted ? Icons.check_rounded : Icons.close_rounded,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 24,
          height: 24,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CircleProgressPainter(
                  progress: data.progress * animation.value,
                  primaryColor: primaryColor,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE5E7EB),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 圆形进度条绘制器
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
    final radius = (size.width - 5) / 2; // 减去strokeWidth

    // 背景圆环
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆弧
    final progressPaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
