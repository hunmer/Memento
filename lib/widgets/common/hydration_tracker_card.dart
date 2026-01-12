import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 饮水追踪卡片组件
///
/// 用于展示每日饮水量目标和连续打卡天数的卡片组件。
/// 显示半圆进度环、剩余饮水量、目标和连续打卡徽章。
///
/// 使用示例：
/// ```dart
/// HydrationTrackerCard(
///   goal: 2.0,
///   consumed: 0.7,
///   unit: 'Liters',
///   streakDays: 5,
/// )
/// ```
class HydrationTrackerCard extends StatefulWidget {
  /// 目标饮水量
  final double goal;

  /// 已摄入水量
  final double consumed;

  /// 单位
  final String unit;

  /// 连续打卡天数
  final int streakDays;

  const HydrationTrackerCard({
    super.key,
    required this.goal,
    required this.consumed,
    this.unit = 'Liters',
    this.streakDays = 0,
  });

  @override
  State<HydrationTrackerCard> createState() => _HydrationTrackerCardState();
}

class _HydrationTrackerCardState extends State<HydrationTrackerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  double get progress => (widget.consumed / widget.goal).clamp(0.0, 1.0);
  double get remaining =>
      (widget.goal - widget.consumed).clamp(0.0, widget.goal);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HydrationTrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal != widget.goal ||
        oldWidget.consumed != widget.consumed ||
        oldWidget.streakDays != widget.streakDays) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    // 优先使用主题颜色，如果主题是蓝色系则使用主题色
    final primaryColor =
        _isBlueTheme(context) ? Theme.of(context).colorScheme.primary : const Color(0xFF007AFF);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: 0.95 + 0.05 * _scaleAnimation.value,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 上部进度环区域
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 半圆进度环
                          SizedBox(
                            width: 224,
                            height: 128,
                            child: Stack(
                              children: [
                                // 背景虚线环
                                CustomPaint(
                                  size: const Size(224, 128),
                                  painter: _DashedArcPainter(
                                    progress: 1.0,
                                    color: isDark
                                        ? primaryColor.withOpacity(0.1)
                                        : const Color(0xFFDBEAFE),
                                    isBackground: true,
                                  ),
                                ),
                                // 进度虚线环（带动画）
                                CustomPaint(
                                  size: const Size(224, 128),
                                  painter: _DashedArcPainter(
                                    progress: progress * _scaleAnimation.value,
                                    color: primaryColor,
                                    isBackground: false,
                                  ),
                                ),
                                // 中间内容：水滴图标和剩余量
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 4,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.water_drop_rounded,
                                        color: primaryColor,
                                        size: 48 * _scaleAnimation.value,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${remaining.toStringAsFixed(1)} ${widget.unit} Left',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                          color: isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 中部目标说明
                    Text(
                      'Drink ${widget.goal.toStringAsFixed(0)} ${widget.unit}\nOf Water Per Day',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 底部连续打卡标签
                    if (widget.streakDays > 0)
                      _StreakBadge(
                        days: widget.streakDays,
                        animation: _fadeAnimation,
                        primaryColor: primaryColor,
                        isDark: isDark,
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

  /// 检查主题是否为蓝色系
  bool _isBlueTheme(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    // 判断主题颜色是否接近蓝色（色相在蓝色范围内）
    final hsl = HSLColor.fromColor(themeColor);
    return hsl.hue >= 190 && hsl.hue <= 250;
  }
}

/// 连续打卡徽章
class _StreakBadge extends StatelessWidget {
  final int days;
  final Animation<double> animation;
  final Color primaryColor;
  final bool isDark;

  const _StreakBadge({
    required this.days,
    required this.animation,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? primaryColor.withOpacity(0.2)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? primaryColor.withOpacity(0.3)
                      : const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days Days Strike',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: primaryColor,
                    size: 18,
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

/// 虚线圆弧绘制器
class _DashedArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isBackground;

  _DashedArcPainter({
    required this.progress,
    required this.color,
    required this.isBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // 虚线参数
    const dashLength = 23.0;
    const gapLength = 12.0;
    const strokeWidth = 12.0;

    // 计算总弧度（半圆，留出端点圆角空间）
    final angleAdjustment = math.asin(strokeWidth / (2 * radius));
    final totalAngle = math.pi - 2 * angleAdjustment;

    // 计算虚线数量
    final totalDashLength = dashLength + gapLength;
    final circumference = totalAngle * radius;
    final dashCount = (circumference / totalDashLength).floor();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 如果是背景，绘制完整的虚线环
    // 如果是进度，只绘制部分虚线
    final maxDashes =
        isBackground ? dashCount : (dashCount * progress).floor();

    for (int i = 0; i < maxDashes; i++) {
      // 计算当前虚线的起始角度
      final dashProgress = i / dashCount;
      final startAngle = math.pi + angleAdjustment + (totalAngle * dashProgress);

      // 计算虚线的弧度长度
      final dashAngle = (dashLength / radius).clamp(0.0, totalAngle * 0.2);

      // 绘制虚线段
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isBackground != isBackground;
  }
}
