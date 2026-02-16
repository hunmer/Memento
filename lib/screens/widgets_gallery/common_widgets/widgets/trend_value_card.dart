import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 趋势数据点
class TrendDataPoint {
  final double value;
  final DateTime? timestamp;

  const TrendDataPoint({required this.value, this.timestamp});

  /// 从 JSON 创建
  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      value: (json['value'] as num).toDouble(),
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'value': value, 'timestamp': timestamp?.toIso8601String()};
  }
}

/// 趋势数值卡片小组件
///
/// 通用的数值展示卡片，支持：
/// - 数值和单位显示（带翻转动画）
/// - 曲线图表（带渐变填充）
class TrendValueCardWidget extends StatefulWidget {
  /// 当前数值
  final double value;

  /// 数值单位
  final String unit;

  /// 图表数据（Y坐标值，0-100范围）
  final List<double> chartData;

  /// 主色调
  final Color? primaryColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const TrendValueCardWidget({
    super.key,
    required this.value,
    required this.unit,
    required this.chartData,
    this.primaryColor,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory TrendValueCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return TrendValueCardWidget(
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      chartData:
          (props['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      primaryColor:
          props['primaryColor'] != null
              ? Color(int.parse(props['primaryColor'] as String))
              : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<TrendValueCardWidget> createState() => _TrendValueCardWidgetState();
}

class _TrendValueCardWidgetState extends State<TrendValueCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
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
    final primaryColor = widget.primaryColor ?? const Color(0xFFF59E0B);
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final subTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    // 根据 size 计算各种尺寸
    final valueFontSize = widget.size.getLargeFontSize() * 0.35;
    final unitFontSize = widget.size.getSubtitleFontSize();
    final strokeWidth = widget.size.getStrokeWidth() * 0.3;

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : null,
              padding: widget.size.getPadding(),
              constraints: widget.size.getHeightConstraints(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图表区域
                  Expanded(
                    child: _buildChart(
                      context,
                      primaryColor,
                      _fadeInAnimation.value,
                      strokeWidth,
                    ),
                  ),
                  SizedBox(height: widget.size.getItemSpacing()),

                  // 数值显示区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 数值和单位
                      SizedBox(
                        height: valueFontSize * 1.2,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: valueFontSize * 1.2,
                              child: AnimatedFlipCounter(
                                value: widget.value * _fadeInAnimation.value,
                                fractionDigits: widget.value % 1 != 0 ? 1 : 0,
                                textStyle: TextStyle(
                                  color: textColor,
                                  fontSize: valueFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(width: widget.size.getSmallSpacing()),
                            SizedBox(
                              height: unitFontSize * 1.2,
                              child: Text(
                                widget.unit,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: unitFontSize,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 右侧箭头按钮
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: subTextColor,
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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

  /// 构建曲线图表
  Widget _buildChart(
    BuildContext context,
    Color primaryColor,
    double animationValue,
    double strokeWidth,
  ) {
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendChartPainter(
          data: widget.chartData,
          primaryColor: primaryColor,
          animationValue: animationValue,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// 趋势图表绘制器
class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color primaryColor;
  final double animationValue;
  final double strokeWidth;

  _TrendChartPainter({
    required this.data,
    required this.primaryColor,
    required this.animationValue,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final pointRadius = strokeWidth * 1.5;

    // 绘制渐变填充
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withOpacity(0.2 * animationValue),
        primaryColor.withOpacity(0),
      ],
    );

    final path = Path();
    final pointDistance = size.width / (data.length - 1);

    // 移动到第一个点
    path.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        // 使用二次贝塞尔曲线平滑连接
        final prevX = (i - 1) * pointDistance;
        final prevY =
            size.height - (data[i - 1] / 100 * size.height * animationValue);
        final cpX = (prevX + x) / 2;

        path.quadraticBezierTo(cpX, prevY, cpX, (prevY + y) / 2);
        path.quadraticBezierTo(cpX, y, x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    final fillPaint =
        Paint()
          ..shader = fillGradient.createShader(rect)
          ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // 绘制曲线
    final linePath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * pointDistance;
        final prevY =
            size.height - (data[i - 1] / 100 * size.height * animationValue);
        final cpX = (prevX + x) / 2;

        linePath.quadraticBezierTo(cpX, prevY, cpX, (prevY + y) / 2);
        linePath.quadraticBezierTo(cpX, y, x, y);
      }
    }

    final linePaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // 绘制数据点
    final isDark = primaryColor.computeLuminance() < 0.5;
    final pointPaint =
        Paint()
          ..color = isDark ? const Color(0xFF1F2937) : Colors.white
          ..style = PaintingStyle.fill;

    final pointStrokePaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.7;

    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
      canvas.drawCircle(Offset(x, y), pointRadius, pointStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
