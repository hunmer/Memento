import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 圆环数据模型
class RingData {
  final double value;
  final Color color;
  final IconData? icon;
  final bool isDiamond;

  const RingData({
    required this.value,
    required this.color,
    this.icon,
    this.isDiamond = false,
  });

  /// 从 JSON 创建
  factory RingData.fromJson(Map<String, dynamic> json) {
    return RingData(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
      icon: json['iconCodePoint'] != null
          ? IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons')
          : null,
      isDiamond: json['isDiamond'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'color': color.value,
      'iconCodePoint': icon?.codePoint,
      'isDiamond': isDiamond,
    };
  }
}

/// 活动圆环小组件
class ActivityRingsCardWidget extends StatefulWidget {
  final String date;
  final int steps;
  final String status;
  final List<RingData> rings;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ActivityRingsCardWidget({
    super.key,
    required this.date,
    required this.steps,
    required this.status,
    required this.rings,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ActivityRingsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final ringsList = (props['rings'] as List<dynamic>?)
            ?.map((e) => RingData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ActivityRingsCardWidget(
      date: props['date'] as String? ?? '',
      steps: props['steps'] as int? ?? 0,
      status: props['status'] as String? ?? '',
      rings: ringsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ActivityRingsCardWidget> createState() =>
      _ActivityRingsCardWidgetState();
}

class _ActivityRingsCardWidgetState extends State<ActivityRingsCardWidget>
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
              width: widget.inline ? double.maxFinite : 400,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(widget.size.getIconSize() + 12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: widget.size.getTitleFontSize() - 6,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '16 Feb',
                            style: TextStyle(
                              fontSize: widget.size.getLegendFontSize() + 2,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(width: widget.size.getSmallSpacing()),
                          Icon(
                            Icons.chevron_right,
                            size: widget.size.getIconSize(),
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: widget.size.getLargeFontSize(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedFlipCounter(
                                  value:
                                      widget.steps.toDouble() *
                                      _animation.value,
                                  textStyle: TextStyle(
                                    fontSize: widget.size.getLargeFontSize(),
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(width: widget.size.getItemSpacing()),
                                Padding(
                                  padding: EdgeInsets.only(bottom: widget.size.getSmallSpacing()),
                                  child: Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize: widget.size.getTitleFontSize() - 6,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: widget.size.getItemSpacing()),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: isDark
                                    ? const Color(0xFFF97316)
                                    : const Color(0xFFF97316),
                                size: widget.size.getIconSize(),
                              ),
                              SizedBox(width: widget.size.getItemSpacing()),
                              Text(
                                widget.status,
                                style: TextStyle(
                                  fontSize: widget.size.getSubtitleFontSize() + 2,
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
                            padding: EdgeInsets.only(left: widget.size.getItemSpacing()),
                            child: _RingWidget(
                              data: widget.rings[index],
                              animation: ringAnimation,
                              isDark: isDark,
                              size: widget.size,
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

class _RingWidget extends StatelessWidget {
  final RingData data;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _RingWidget({
    required this.data,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = size.getIconSize() * 1.8;
    final strokeWidth = ringSize * 0.1;
    final centerSize = ringSize * 0.3;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: data.value / 100 * animation.value,
              color: data.color,
              backgroundColor:
                  isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              strokeWidth: strokeWidth,
            ),
            child: Center(child: _buildCenterWidget(centerSize)),
          );
        },
      ),
    );
  }

  Widget _buildCenterWidget(double centerSize) {
    if (data.isDiamond) {
      return Container(
        width: centerSize,
        height: centerSize,
        decoration: BoxDecoration(
          color: data.color,
          borderRadius: BorderRadius.circular(centerSize / 4),
        ),
        child: Center(
          child: Container(
            width: centerSize / 3,
            height: centerSize / 3,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    if (data.icon != null) {
      return Icon(data.icon, size: centerSize * 0.7, color: data.color);
    }

    return const SizedBox.shrink();
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -90.0 * (3.14159 / 180.0);
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
