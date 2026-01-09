import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 每日条形图卡片示例
class DailyBarChartCardExample extends StatelessWidget {
  const DailyBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日条形图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DailyBarChartCardWidget(
            title: 'Monthly Steps',
            subtitle: 'January 2025',
            value: 187297,
            unit: 'steps',
            bars: [
              DailyBarData(height: 0.30, color: DailyBarColor.red),
              DailyBarData(height: 0.45, color: DailyBarColor.red),
              DailyBarData(height: 0.65, color: DailyBarColor.teal),
              DailyBarData(height: 0.25, color: DailyBarColor.red),
              DailyBarData(height: 0.40, color: DailyBarColor.red),
              DailyBarData(height: 0.70, color: DailyBarColor.teal),
              DailyBarData(height: 0.55, color: DailyBarColor.teal),
              DailyBarData(height: 0.15, color: DailyBarColor.red),
              DailyBarData(height: 0.85, color: DailyBarColor.teal),
              DailyBarData(height: 0.35, color: DailyBarColor.red),
              DailyBarData(height: 0.20, color: DailyBarColor.red),
              DailyBarData(height: 0.60, color: DailyBarColor.teal),
              DailyBarData(height: 0.52, color: DailyBarColor.teal),
              DailyBarData(height: 0.90, color: DailyBarColor.teal),
              DailyBarData(height: 0.40, color: DailyBarColor.red),
              DailyBarData(height: 0.32, color: DailyBarColor.red),
              DailyBarData(height: 0.75, color: DailyBarColor.teal),
              DailyBarData(height: 0.28, color: DailyBarColor.red),
              DailyBarData(height: 0.48, color: DailyBarColor.red),
              DailyBarData(height: 0.62, color: DailyBarColor.teal),
              DailyBarData(height: 0.88, color: DailyBarColor.teal),
              DailyBarData(height: 0.72, color: DailyBarColor.teal),
              DailyBarData(height: 0.38, color: DailyBarColor.red),
              DailyBarData(height: 0.18, color: DailyBarColor.red),
              DailyBarData(height: 0.42, color: DailyBarColor.red),
              DailyBarData(height: 0.58, color: DailyBarColor.teal),
              DailyBarData(height: 0.82, color: DailyBarColor.teal),
              DailyBarData(height: 0.68, color: DailyBarColor.teal),
              DailyBarData(height: 0.55, color: DailyBarColor.teal),
            ],
          ),
        ),
      ),
    );
  }
}

/// 每日条形数据
class DailyBarData {
  final double height;
  final DailyBarColor color;

  const DailyBarData({required this.height, required this.color});
}

/// 条形颜色枚举
enum DailyBarColor { teal, red }

/// 每日条形图小组件
class DailyBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final List<DailyBarData> bars;

  const DailyBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.bars,
  });

  @override
  State<DailyBarChartCardWidget> createState() =>
      _DailyBarChartCardWidgetState();
}

class _DailyBarChartCardWidgetState extends State<DailyBarChartCardWidget>
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
              width: 384,
              height: 280,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    // 右上角装饰点阵
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: isDark ? 0.3 : 0.2,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topRight,
                              radius: 1.0,
                              colors: [
                                Colors.grey.shade600,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.8],
                            ),
                          ),
                          child: CustomPaint(
                            painter: _DotPatternPainter(
                              color: Colors.grey.shade600,
                              dotSize: 1,
                              spacing: 6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 内容
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题和图标
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.directions_walk,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 数值显示
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AnimatedFlipCounter(
                                value:
                                    widget.value.toDouble() * _animation.value,
                                fractionDigits: 0,
                                textStyle: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : Colors.grey.shade900,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.unit,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // 条形图
                          Expanded(
                            child: _DailyBars(
                              bars: widget.bars,
                              animation: _animation,
                            ),
                          ),
                        ],
                      ),
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

/// 每日条形图组件
class _DailyBars extends StatelessWidget {
  final List<DailyBarData> bars;
  final Animation<double> animation;

  const _DailyBars({required this.bars, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = const Color(0xFF2DD4BF);
    final redColor = const Color(0xFFFB7185);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars.length, (index) {
        final bar = bars[index];
        final barAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * 0.025,
            0.55 + index * 0.025,
            curve: Curves.easeOutCubic,
          ),
        );

        final baseColor =
            bar.color == DailyBarColor.teal ? tealColor : redColor;
        final barColor = baseColor.withOpacity(
          bar.color == DailyBarColor.teal ? 1.0 : (isDark ? 0.9 : 0.8),
        );

        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: AnimatedBuilder(
            animation: barAnimation,
            builder: (context, child) {
              return Container(
                width: 6,
                height: 112 * bar.height * barAnimation.value,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// 点阵装饰画笔
class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;

  _DotPatternPainter({
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) => false;
}
