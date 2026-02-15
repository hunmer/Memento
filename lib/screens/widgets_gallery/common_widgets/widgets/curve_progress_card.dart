import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 曲线进度卡片小组件
class CurveProgressCardWidget extends StatefulWidget {
  /// 主数值
  final double value;

  /// 数值标签
  final String label;

  /// 变化量
  final double change;

  /// 变化百分比
  final double changePercent;

  /// 单位
  final String unit;

  /// 图标
  final IconData icon;

  /// 分类标签
  final String categoryLabel;

  /// 更新时间文本
  final String lastUpdated;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const CurveProgressCardWidget({
    super.key,
    required this.value,
    required this.label,
    required this.change,
    required this.changePercent,
    this.unit = '',
    this.icon = Icons.schedule,
    this.categoryLabel = 'Progress',
    this.lastUpdated = '',
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例
  factory CurveProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CurveProgressCardWidget(
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      label: props['label'] as String? ?? '',
      change: (props['change'] as num?)?.toDouble() ?? 0.0,
      changePercent: (props['changePercent'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      icon: props['icon'] != null
          ? IconData(props['icon'] as int, fontFamily: 'MaterialIcons')
          : Icons.schedule,
      categoryLabel: props['categoryLabel'] as String? ?? 'Progress',
      lastUpdated: props['lastUpdated'] as String? ?? '',
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<CurveProgressCardWidget> createState() =>
      _CurveProgressCardWidgetState();
}

class _CurveProgressCardWidgetState extends State<CurveProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
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

    // 颜色定义
    final backgroundColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final accentColor = const Color(0xFF4ADE80);
    final changeColor = widget.change >= 0 ? accentColor : Colors.red;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标签行
                  _buildHeaderRow(
                    icon: widget.icon,
                    label: widget.categoryLabel,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 主内容区域：数值 + 曲线图
                  _buildMainContent(
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 底部信息行
                  _buildFooterRow(
                    changeColor: changeColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 顶部标签行
  Widget _buildHeaderRow({
    required IconData icon,
    required String label,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: secondaryTextColor),
        SizedBox(width: widget.size.getItemSpacing()),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.4,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  /// 主内容区域：数值 + 曲线图
  Widget _buildMainContent({
    required bool isDark,
    required Color textColor,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 数值部分
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 数值 + 趋势图标
              SizedBox(
                height: 54,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 52,
                      child: AnimatedFlipCounter(
                        value: widget.value * _progressAnimation.value,
                        fractionDigits: widget.value % 1 != 0 ? 2 : 0,
                        textStyle: TextStyle(
                          fontSize: widget.size.getLargeFontSize(),
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.0,
                        ),
                      ),
                    ),
                    if (widget.unit.isNotEmpty) ...[
                      SizedBox(width: widget.size.getItemSpacing() - 2),
                      SizedBox(
                        height: 22,
                        child: Text(
                          widget.unit,
                          style: TextStyle(
                            fontSize: widget.size.getSubtitleFontSize(),
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: widget.size.getItemSpacing() / 2),
                    Transform.translate(
                      offset: const Offset(0, 4),
                      child: Icon(
                        widget.change >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 24,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: widget.size.getItemSpacing()),
              // 标签
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.size.getSubtitleFontSize(),
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),

        // 曲线进度图
        SizedBox(
          width: 144,
          height: 80,
          child: CustomPaint(
            painter: _CurveProgressPainter(
              progress: _progressAnimation.value,
              progressColor: accentColor,
              backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 底部信息行
  Widget _buildFooterRow({
    required Color changeColor,
    required Color secondaryTextColor,
  }) {
    final changePrefix = widget.change >= 0 ? '+' : '';
    final changeText =
        '$changePrefix${widget.change.toStringAsFixed(0)} (${widget.changePercent.toStringAsFixed(2)}%)';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          changeText,
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.bold,
            color: changeColor,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          widget.lastUpdated,
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

/// 曲线进度图绘制器
class _CurveProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CurveProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.57; // 80/140 ≈ 0.57
    final centerY = size.height * 0.25; // 15/60 = 0.25

    // 根据进度裁剪路径
    final fullPath = Path();
    fullPath.moveTo(0, size.height * 0.75);
    fullPath.relativeQuadraticBezierTo(
      size.width * 0.107,
      size.height * 0.167, // Q 15 55
      size.width * 0.214,
      0, // 30 45 (relative)
    );
    fullPath.relativeQuadraticBezierTo(
      size.width * 0.107,
      -size.height * 0.167, // T 55 35
      size.width * 0.214,
      -size.height * 0.333, // T 80 15 (relative)
    );
    fullPath.relativeQuadraticBezierTo(
      size.width * 0.107,
      size.height * 0.333, // T 105 35
      size.width * 0.214,
      0, // T 115 25 (relative)
    );
    fullPath.relativeQuadraticBezierTo(
      size.width * 0.107,
      0, // Q 100 25
      size.width * 0.214,
      size.height * 0.333, // T 140 45 (relative)
    );

    // 使用 PathMetrics 实现进度动画
    final pathMetric = fullPath.computeMetrics().first;
    final extractPath = pathMetric.extractPath(
      0.0,
      pathMetric.length * progress,
    );

    final paint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);

    // 绘制进度点（动画显示）
    if (progress > 0.1) {
      final dotPaint =
          Paint()
            ..color = progressColor
            ..style = PaintingStyle.fill;

      final borderPaint =
          Paint()
            ..color = backgroundColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;

      canvas.drawCircle(Offset(centerX, centerY), 4.5, dotPaint);
      canvas.drawCircle(Offset(centerX, centerY), 4.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
