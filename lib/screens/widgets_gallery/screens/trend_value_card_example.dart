import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 趨勢數值卡片示例
class TrendValueCardExample extends StatelessWidget {
  const TrendValueCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('趨勢數值卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TrendValueCardWidget(
            value: 167.4,
            unit: 'lbs',
            trendValue: -0.8,
            trendUnit: 'lbs',
            chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
            date: 'Jan 12, 2028',
            additionalInfo: ['26.1 BMI', 'Overweight'],
            trendLabel: 'vs last week',
            primaryColor: Color(0xFFF59E0B),
          ),
        ),
      ),
    );
  }
}

/// 趨勢數據點
class TrendDataPoint {
  final double value;
  final DateTime? timestamp;

  const TrendDataPoint({
    required this.value,
    this.timestamp,
  });
}

/// 趨勢數值卡片小組件
///
/// 通用的數值展示卡片，支持：
/// - 數值和單位顯示（帶翻轉動畫）
/// - 趨勢指示（上升/下降）
/// - 曲線圖表（帶漸變填充）
/// - 附加信息（日期、BMI等）
class TrendValueCardWidget extends StatefulWidget {
  /// 當前數值
  final double value;

  /// 數值單位
  final String unit;

  /// 趨勢變化值（正數上升，負數下降）
  final double trendValue;

  /// 趨勢單位
  final String trendUnit;

  /// 圖表數據（Y坐標值，0-100範圍）
  final List<double> chartData;

  /// 日期文本
  final String date;

  /// 附加信息列表
  final List<String> additionalInfo;

  /// 趨勢標籤
  final String trendLabel;

  /// 主色調
  final Color? primaryColor;

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
  });

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
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final trendDownColor = const Color(0xFFEF4444);

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: Container(
              width: 384,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
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
                  // 圖表區域
                  _buildChart(context, primaryColor, _fadeInAnimation.value),
                  const SizedBox(height: 16),

                  // 數值顯示區域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 數值和單位
                      SizedBox(
                        height: 48,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 48,
                              child: AnimatedFlipCounter(
                                value: widget.value * _fadeInAnimation.value,
                                fractionDigits: widget.value % 1 != 0 ? 1 : 0,
                                textStyle: TextStyle(
                                  color: textColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 24,
                              child: Text(
                                widget.unit,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 右側箭頭按鈕
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: subTextColor,
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 趨勢指示
                  _buildTrendIndicator(
                    context,
                    widget.trendValue,
                    widget.trendUnit,
                    widget.trendLabel,
                    trendDownColor,
                    textColor,
                  ),
                  const SizedBox(height: 24),

                  // 附加信息
                  _buildAdditionalInfo(widget.date, widget.additionalInfo, textColor, subTextColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 構建曲線圖表
  Widget _buildChart(BuildContext context, Color primaryColor, double animationValue) {
    return SizedBox(
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _TrendChartPainter(
          data: widget.chartData,
          primaryColor: primaryColor,
          animationValue: animationValue,
        ),
      ),
    );
  }

  /// 構建趨勢指示器
  Widget _buildTrendIndicator(
    BuildContext context,
    double trendValue,
    String trendUnit,
    String trendLabel,
    Color trendColor,
    Color textColor,
  ) {
    final isTrendDown = trendValue < 0;

    return Row(
      children: [
        Transform.rotate(
          angle: isTrendDown ? -0.785 : 0.785, // 45度旋轉
          child: Icon(
            isTrendDown ? Icons.arrow_downward : Icons.arrow_upward,
            color: trendColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${isTrendDown ? '' : '+'}${trendValue.toStringAsFixed(1)}$trendUnit ',
                style: TextStyle(
                  color: trendColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: trendLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 構建附加信息
  Widget _buildAdditionalInfo(
    String date,
    List<String> info,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      children: [
        SizedBox(
          height: 20,
          child: Text(
            date,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
        for (int i = 0; i < info.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 20,
              child: Text(
                '•',
                style: TextStyle(
                  color: subTextColor.withOpacity(0.5),
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
            child: Text(
              info[i],
              style: TextStyle(
                color: textColor,
                fontSize: 14,
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

/// 趨勢圖表繪製器
class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color primaryColor;
  final double animationValue;

  _TrendChartPainter({
    required this.data,
    required this.primaryColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final isDark = primaryColor.computeLuminance() < 0.5;

    // 繪製漸變填充
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

    // 移動到第一個點
    path.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        // 使用二次貝塞爾曲線平滑連接
        final prevX = (i - 1) * pointDistance;
        final prevY = size.height - (data[i - 1] / 100 * size.height * animationValue);
        final cpX = (prevX + x) / 2;

        path.quadraticBezierTo(cpX, prevY, cpX, (prevY + y) / 2);
        path.quadraticBezierTo(cpX, y, x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // 繪製曲線
    final linePath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * pointDistance;
        final prevY = size.height - (data[i - 1] / 100 * size.height * animationValue);
        final cpX = (prevX + x) / 2;

        linePath.quadraticBezierTo(cpX, prevY, cpX, (prevY + y) / 2);
        linePath.quadraticBezierTo(cpX, y, x, y);
      }
    }

    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // 繪製數據點
    final pointPaint = Paint()
      ..color = isDark ? const Color(0xFF1F2937) : Colors.white
      ..style = PaintingStyle.fill;

    final pointStrokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 4, pointStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor;
  }
}
