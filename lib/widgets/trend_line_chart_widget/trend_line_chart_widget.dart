import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 趋势折线图小组件
///
/// 一个带有动画效果的折线图组件，支持显示标题、图标、数值和时间轴标签。
/// 适用于展示温度、价格、指标等带有时间趋势的数据。
///
/// 示例用法：
/// ```dart
/// TrendLineChartWidget(
///   title: 'Temperature',
///   icon: Icons.thermostat,
///   value: 4.875,
///   dataPoints: [
///     Offset(5, 90),
///     Offset(15, 85),
///     // ... 更多数据点
///   ],
///   timeLabels: ['8:00am', '10:00am', '12:00am', '1:00pm', '3:00pm'],
///   primaryColor: Color(0xFF0284C7),
///   valueColor: Color(0xFF2563EB),
/// )
/// ```
class TrendLineChartWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 图标
  final IconData icon;

  /// 显示的数值
  final double value;

  /// 数据点坐标（相对坐标，0-320范围）
  ///
  /// X 轴范围：0-320，Y 轴范围：0-120
  /// 数据点会根据容器大小自动缩放
  final List<Offset> dataPoints;

  /// 时间轴标签
  ///
  /// 显示在折线图下方的标签列表
  final List<String> timeLabels;

  /// 主色调
  ///
  /// 用于折线图的渐变色起始和结束
  final Color primaryColor;

  /// 数值颜色（用于渐变中间色）
  ///
  /// 如果为 null，则使用 primaryColor
  final Color? valueColor;

  /// 菜单按钮点击回调
  final VoidCallback? onMenuPressed;

  const TrendLineChartWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.dataPoints,
    required this.timeLabels,
    required this.primaryColor,
    this.valueColor,
    this.onMenuPressed,
  });

  @override
  State<TrendLineChartWidget> createState() => _TrendLineChartWidgetState();
}

class _TrendLineChartWidgetState extends State<TrendLineChartWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey.shade900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        _MenuButton(
                          isDark: isDark,
                          onPressed: widget.onMenuPressed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 数值显示
                    AnimatedFlipCounter(
                      value: widget.value * _animation.value,
                      fractionDigits: widget.value % 1 != 0 ? 3 : 0,
                      textStyle: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 折线图
                    _LineChart(
                      dataPoints: widget.dataPoints,
                      primaryColor: widget.primaryColor,
                      valueColor: widget.valueColor,
                      animation: _animation,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 4),
                    // 时间轴标签
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: widget.timeLabels.map((label) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
}

/// 菜单按钮
class _MenuButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onPressed;

  const _MenuButton({
    required this.isDark,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            Icons.more_vert,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// 折线图组件
class _LineChart extends StatelessWidget {
  final List<Offset> dataPoints;
  final Color primaryColor;
  final Color? valueColor;
  final Animation<double> animation;
  final bool isDark;

  const _LineChart({
    required this.dataPoints,
    required this.primaryColor,
    this.valueColor,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          // 背景网格线
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (index) => Container(
                  height: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
              ),
            ),
          ),
          // 折线
          CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _LineChartPainter(
              dataPoints: dataPoints,
              progress: animation.value,
              primaryColor: primaryColor,
              valueColor: valueColor,
              graphWidth: 320,
              graphHeight: 120,
            ),
          ),
        ],
      ),
    );
  }
}

/// 折线图画笔
class _LineChartPainter extends CustomPainter {
  final List<Offset> dataPoints;
  final double progress;
  final Color primaryColor;
  final Color? valueColor;
  final double graphWidth;
  final double graphHeight;

  _LineChartPainter({
    required this.dataPoints,
    required this.progress,
    required this.primaryColor,
    this.valueColor,
    required this.graphWidth,
    required this.graphHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 计算缩放比例
    final scaleX = size.width / graphWidth;
    final scaleY = size.height / graphHeight;

    // 创建渐变
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        primaryColor,
        valueColor ?? primaryColor,
        primaryColor.withOpacity(0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient;

    // 构建路径
    final path = Path();
    final firstPoint = dataPoints.first;
    path.moveTo(firstPoint.dx * scaleX, firstPoint.dy * scaleY);

    // 计算当前动画应该绘制到第几个点
    final totalSegments = dataPoints.length - 1;
    final currentSegment = (totalSegments * progress).floor();
    final segmentProgress = (totalSegments * progress) - currentSegment;

    for (int i = 1; i <= currentSegment && i < dataPoints.length; i++) {
      final point = dataPoints[i];
      path.lineTo(point.dx * scaleX, point.dy * scaleY);
    }

    // 绘制当前正在动画的线段
    if (currentSegment < totalSegments) {
      final startPoint = dataPoints[currentSegment];
      final endPoint = dataPoints[currentSegment + 1];
      final currentX = startPoint.dx +
          (endPoint.dx - startPoint.dx) * segmentProgress * scaleX;
      final currentY = startPoint.dy +
          (endPoint.dy - startPoint.dy) * segmentProgress * scaleY;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dataPoints != dataPoints;
  }
}
