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
/// - 趋势指示（上升/下降）
/// - 曲线图表（带渐变填充）
/// - 附加信息（日期、BMI等）
class TrendValueCardWidget extends StatefulWidget {
  /// 当前数值
  final double value;

  /// 数值单位
  final String unit;

  /// 趋势变化值（正数上升，负数下降）
  final double trendValue;

  /// 趋势单位
  final String trendUnit;

  /// 图表数据（Y坐标值，0-100范围）
  final List<double> chartData;

  /// 日期文本
  final String date;

  /// 附加信息列表
  final List<String> additionalInfo;

  /// 趋势标签
  final String trendLabel;

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
    required this.trendValue,
    required this.trendUnit,
    required this.chartData,
    required this.date,
    this.additionalInfo = const [],
    this.trendLabel = 'vs last week',
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
      trendValue: (props['trendValue'] as num?)?.toDouble() ?? 0.0,
      trendUnit: props['trendUnit'] as String? ?? '',
      chartData:
          (props['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      date: props['date'] as String? ?? '',
      additionalInfo:
          (props['additionalInfo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      trendLabel: props['trendLabel'] as String? ?? 'vs last week',
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
    final trendDownColor = const Color(0xFFEF4444);

    // 根据 size 计算各种尺寸
    final valueFontSize = widget.size.getLargeFontSize() * 0.35;
    final unitFontSize = widget.size.getSubtitleFontSize();
    final trendFontSize = widget.size.getSubtitleFontSize();
    final infoFontSize = widget.size.getLegendFontSize();
    final chartHeight = widget.size.getHeightConstraints().maxHeight * 0.35;
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图表区域
                  _buildChart(
                    context,
                    primaryColor,
                    _fadeInAnimation.value,
                    chartHeight,
                    strokeWidth,
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
                  SizedBox(height: widget.size.getSmallSpacing()),

                  // 趋势指示
                  _buildTrendIndicator(
                    context,
                    widget.trendValue,
                    widget.trendUnit,
                    widget.trendLabel,
                    trendDownColor,
                    textColor,
                    trendFontSize,
                  ),
                  if (widget.additionalInfo.isNotEmpty) ...[
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 附加信息
                    _buildAdditionalInfo(
                      widget.date,
                      widget.additionalInfo,
                      textColor,
                      subTextColor,
                      infoFontSize,
                    ),
                  ],
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
    double chartHeight,
    double strokeWidth,
  ) {
    return SizedBox(
      height: chartHeight,
      child: CustomPaint(
        size: Size(double.infinity, chartHeight),
        painter: _TrendChartPainter(
          data: widget.chartData,
          primaryColor: primaryColor,
          animationValue: animationValue,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }

  /// 构建趋势指示器
  Widget _buildTrendIndicator(
    BuildContext context,
    double trendValue,
    String trendUnit,
    String trendLabel,
    Color trendColor,
    Color textColor,
    double trendFontSize,
  ) {
    final isTrendDown = trendValue < 0;

    return Row(
      children: [
        Transform.rotate(
          angle: isTrendDown ? -0.785 : 0.785, // 45度旋转
          child: Icon(
            isTrendDown ? Icons.arrow_downward : Icons.arrow_upward,
            color: trendColor,
            size: widget.size.getIconSize(),
          ),
        ),
        SizedBox(width: widget.size.getItemSpacing()),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text:
                    '${isTrendDown ? '' : '+'}${trendValue.toStringAsFixed(1)}$trendUnit ',
                style: TextStyle(
                  color: trendColor,
                  fontSize: trendFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: trendLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: trendFontSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建附加信息
  Widget _buildAdditionalInfo(
    String date,
    List<String> info,
    Color textColor,
    Color subTextColor,
    double infoFontSize,
  ) {
    return Row(
      children: [
        SizedBox(
          height: infoFontSize * 1.2,
          child: Text(
            date,
            style: TextStyle(
              color: subTextColor,
              fontSize: infoFontSize,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
        for (int i = 0; i < info.length; i++) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.size.getItemSpacing(),
            ),
            child: SizedBox(
              height: infoFontSize * 1.2,
              child: Text(
                '•',
                style: TextStyle(
                  color: subTextColor.withOpacity(0.5),
                  fontSize: infoFontSize,
                  height: 1.0,
                ),
              ),
            ),
          ),
          SizedBox(
            height: infoFontSize * 1.2,
            child: Text(
              info[i],
              style: TextStyle(
                color: textColor,
                fontSize: infoFontSize,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
        ],
      ],
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
