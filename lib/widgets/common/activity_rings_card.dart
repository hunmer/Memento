import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 活动圆环卡片
///
/// 展示活动数据的圆环进度卡片，支持多个圆环指标和动画效果。
/// 可用于步数、卡路里、运动时长等健康数据展示。
class ActivityRingsCard extends StatefulWidget {
  /// 日期文本
  final String date;

  /// 主要数值（如步数）
  final int primaryValue;

  /// 状态文本
  final String status;

  /// 圆环数据列表
  final List<RingCardData> rings;

  /// 主数值单位
  final String unit;

  const ActivityRingsCard({
    super.key,
    required this.date,
    required this.primaryValue,
    required this.status,
    required this.rings,
    this.unit = 'steps',
  });

  @override
  State<ActivityRingsCard> createState() => _ActivityRingsCardState();
}

class _ActivityRingsCardState extends State<ActivityRingsCard>
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
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 日期和导航
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 主数值和圆环
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 主数值显示
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 54,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 52,
                                  child: AnimatedFlipCounter(
                                    value: widget.primaryValue.toDouble() *
                                        _animation.value,
                                    textStyle: TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 22,
                                  child: Text(
                                    widget.unit,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: isDark
                                    ? const Color(0xFFF97316)
                                    : const Color(0xFFF97316),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.status,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFD1D5DB)
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // 圆环列表
                      Row(
                        children: List.generate(widget.rings.length, (index) {
                          final ringAnimation = CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.08,
                              0.5 + index * 0.08,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _RingWidget(
                              data: widget.rings[index],
                              animation: ringAnimation,
                              isDark: isDark,
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

/// 单个圆环组件
class _RingWidget extends StatelessWidget {
  final RingCardData data;
  final Animation<double> animation;
  final bool isDark;

  const _RingWidget({
    required this.data,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: data.value / 100 * animation.value,
              color: data.color,
              backgroundColor:
                  isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
            ),
            child: Center(child: _buildCenterWidget()),
          );
        },
      ),
    );
  }

  Widget _buildCenterWidget() {
    if (data.isDiamond) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: data.color,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    if (data.icon != null) {
      return Icon(data.icon, size: 18, color: data.color);
    }

    return const SizedBox.shrink();
  }
}

/// 圆环绘制器
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    final strokeWidth = 4.0;

    // 背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -90.0 * (3.14159 / 180.0); // 从顶部开始
      final sweepAngle = 2 * 3.14159 * progress;

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
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// 圆环卡片数据模型
///
/// 用于配置单个圆环的显示内容。
class RingCardData {
  /// 进度值（0-100）
  final double value;

  /// 进度颜色
  final Color color;

  /// 中心图标（可选）
  final IconData? icon;

  /// 是否显示钻石形状
  final bool isDiamond;

  const RingCardData({
    required this.value,
    required this.color,
    this.icon,
    this.isDiamond = false,
  });

  /// 创建带图标的圆环数据
  factory RingCardData.withIcon({
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return RingCardData(
      value: value,
      color: color,
      icon: icon,
    );
  }

  /// 创建钻石形状的圆环数据
  factory RingCardData.withDiamond({
    required double value,
    required Color color,
  }) {
    return RingCardData(
      value: value,
      color: color,
      isDiamond: true,
    );
  }

  /// 创建仅进度条的圆环数据
  factory RingCardData.progressOnly({
    required double value,
    required Color color,
  }) {
    return RingCardData(
      value: value,
      color: color,
    );
  }
}
