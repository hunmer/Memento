import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 条形颜色枚举
enum DailyBarColor { teal, red }

/// 条形颜色扩展
extension DailyBarColorExtension on DailyBarColor {
  String toJson() => name;

  static DailyBarColor fromJson(String value) {
    return DailyBarColor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DailyBarColor.teal,
    );
  }
}

/// 每日条形数据
class DailyBarData {
  final double height;
  final DailyBarColor color;

  const DailyBarData({required this.height, required this.color});

  /// 从 JSON 创建
  factory DailyBarData.fromJson(Map<String, dynamic> json) {
    return DailyBarData(
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      color: DailyBarColorExtension.fromJson(json['color'] as String? ?? 'teal'),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'color': color.toJson(),
    };
  }
}

/// 每日条形图小组件
class DailyBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final List<DailyBarData> bars;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const DailyBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.bars,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DailyBarChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final barsList = (props['bars'] as List<dynamic>?)?.map((e) => DailyBarData.fromJson(e as Map<String, dynamic>)).toList() ?? const [];

    return DailyBarChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      value: props['value'] as int? ?? 0,
      unit: props['unit'] as String? ?? '',
      bars: barsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<DailyBarChartCardWidget> createState() => _DailyBarChartCardWidgetState();
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
              width: widget.inline ? double.maxFinite : 384,
              height: widget.inline ? double.maxFinite : 280,
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
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(40)),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return RadialGradient(
                              center: Alignment.topRight,
                              radius: 1.0,
                              colors: [Colors.black, Colors.transparent],
                              stops: const [0.0, 0.8],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: CustomPaint(
                            size: const Size(128, 128),
                            painter: _DotPatternPainter(
                              color: Colors.grey.shade600.withOpacity(isDark ? 0.3 : 0.2),
                              dotSize: 1,
                              spacing: 6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: widget.size.getPadding(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade900)),
                                  SizedBox(height: widget.size.getItemSpacing() / 2),
                                  Text(widget.subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
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
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.directions_walk, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                          SizedBox(height: widget.size.getItemSpacing()),
                          SizedBox(
                            height: 56,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 280,
                                  height: 56,
                                  child: AnimatedFlipCounter(
                                    value: widget.value.toDouble() * _animation.value,
                                    fractionDigits: 0,
                                    textStyle: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.grey.shade900,
                                      letterSpacing: -1,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 28,
                                  child: Text(widget.unit, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: widget.size.getTitleSpacing()),
                          Expanded(
                            child: _DailyBars(bars: widget.bars, animation: _animation, size: widget.size),
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

class _DailyBars extends StatelessWidget {
  final List<DailyBarData> bars;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _DailyBars({required this.bars, required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = const Color(0xFF2DD4BF);
    final redColor = const Color(0xFFFB7185);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars.length, (index) {
        final bar = bars[index];
        final step = 0.015;
        final barAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(index * step, 0.55 + index * step, curve: Curves.easeOutCubic),
        );

        final baseColor = bar.color == DailyBarColor.teal ? tealColor : redColor;
        final barColor = baseColor.withOpacity(bar.color == DailyBarColor.teal ? 1.0 : (isDark ? 0.9 : 0.8));

        return Padding(
          padding: EdgeInsets.only(right: size.getItemSpacing() / 3),
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

class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;

  _DotPatternPainter({required this.color, required this.dotSize, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) => false;
}
