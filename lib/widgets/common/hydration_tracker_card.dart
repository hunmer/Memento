import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
///   size: const MediumSize(),
///   titleText: '每日饮水 2 Liters',
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

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 标题文本
  final String? titleText;

  const HydrationTrackerCard({
    super.key,
    required this.goal,
    required this.consumed,
    this.unit = 'Liters',
    this.streakDays = 0,
    this.size = const MediumSize(),
    this.titleText,
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
        _isBlueTheme(context)
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF007AFF);

    // 根据 size 计算尺寸
    final padding = widget.size.getPadding();
    final iconSize = widget.size.getIconSize();
    final titleFontSize = widget.size.getTitleFontSize();
    widget.size.getSubtitleFontSize();
    final strokeWidth = widget.size.getStrokeWidth();
    final containerSize = iconSize * widget.size.iconContainerScale;
    final titleSpacing = widget.size.getTitleSpacing();
    final smallSpacing = widget.size.getSmallSpacing();

    // 进度环尺寸基于容器大小
    final arcWidth = containerSize * 3.5;
    final arcHeight = containerSize * 2;
    final waterIconSize = containerSize * 0.8;

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
                width: containerSize * 6,
                constraints: widget.size.getHeightConstraints(),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: containerSize,
                      offset: Offset(0, containerSize * 0.5),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: containerSize * 0.4,
                      offset: Offset(0, containerSize * 0.2),
                    ),
                  ],
                ),
                padding: padding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 上部进度环区域
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 半圆进度环
                          SizedBox(
                            width: arcWidth,
                            height: arcHeight,
                            child: Stack(
                              children: [
                                // 背景虚线环
                                CustomPaint(
                                  size: Size(arcWidth, arcHeight),
                                  painter: _DashedArcPainter(
                                    progress: 1.0,
                                    color:
                                        isDark
                                            ? primaryColor.withOpacity(0.1)
                                            : const Color(0xFFDBEAFE),
                                    isBackground: true,
                                    strokeWidth: strokeWidth,
                                  ),
                                ),
                                // 进度虚线环（带动画）
                                CustomPaint(
                                  size: Size(arcWidth, arcHeight),
                                  painter: _DashedArcPainter(
                                    progress: progress * _scaleAnimation.value,
                                    color: primaryColor,
                                    isBackground: false,
                                    strokeWidth: strokeWidth,
                                  ),
                                ),
                                // 中间内容：水滴图标和剩余量
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: smallSpacing,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.water_drop_rounded,
                                        color: primaryColor,
                                        size:
                                            waterIconSize *
                                            _scaleAnimation.value,
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

                    SizedBox(height: smallSpacing),

                    // 中部目标说明
                    Text(
                      widget.titleText ??
                          '${widget.goal.toStringAsFixed(0)} ${widget.unit}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),

                    SizedBox(height: titleSpacing * 0.2),

                    // 底部连续打卡标签
                    if (widget.streakDays > 0)
                      _StreakBadge(
                        days: widget.streakDays,
                        animation: _fadeAnimation,
                        primaryColor: primaryColor,
                        isDark: isDark,
                        size: widget.size,
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
  final HomeWidgetSize size;

  const _StreakBadge({
    required this.days,
    required this.animation,
    required this.primaryColor,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size.getIconSize();
    final fontSize = size.getSubtitleFontSize();
    final horizontalPadding = iconSize * 0.8;
    final verticalPadding = iconSize * 0.4;
    final spacing = size.getSmallSpacing() * 1.5;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? primaryColor.withOpacity(0.2)
                        : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(iconSize * 0.8),
                border: Border.all(
                  color:
                      isDark
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
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: primaryColor,
                    size: iconSize * 0.75,
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
  final double strokeWidth;

  _DashedArcPainter({
    required this.progress,
    required this.color,
    required this.isBackground,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth;

    // 虚线参数（基于 strokeWidth 比例计算）
    final dashLength = strokeWidth * 1.9;

    // 计算总弧度（半圆，留出端点圆角空间）
    final angleAdjustment = math.asin(strokeWidth / (2 * radius));
    final totalAngle = math.pi - 2 * angleAdjustment;
    final totalArcLength = totalAngle * radius;

    // 计算虚线数量（最多10个，且必须是偶数）
    final minGapLength = 10.0;
    final calculatedDashCount =
        (totalArcLength / (dashLength + minGapLength)).floor();
    final dashCount = (calculatedDashCount.clamp(0, 10) ~/ 2) * 2;

    // 重新计算间隙长度，让虚线在半圆范围内均匀分布（确保左右对齐）
    final gapLength =
        dashCount > 1
            ? (totalArcLength - dashCount * dashLength) / (dashCount - 1)
            : 0.0;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // 如果是背景，绘制完整的虚线环
    // 如果是进度，只绘制部分虚线
    final maxDashes = isBackground ? dashCount : (dashCount * progress).floor();

    for (int i = 0; i < maxDashes; i++) {
      // 计算当前虚线的起始角度（从左端开始）
      final startOffset = i * (dashLength + gapLength);
      final startAngle = math.pi + angleAdjustment + (startOffset / radius);

      // 计算虚线的弧度长度
      final dashAngle = dashLength / radius;

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
        oldDelegate.isBackground != isBackground ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
