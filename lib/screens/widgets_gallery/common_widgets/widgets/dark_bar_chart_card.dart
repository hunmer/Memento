import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 柱状图趋势枚举
enum BarChartTrend { up, down, neutral }

/// 睡眠时长统计卡片小组件
///
/// 显示睡眠时长、趋势和睡眠周期可视化
class DarkBarChartCard extends StatefulWidget {
  /// 睡眠时长（分钟）
  final int durationInMinutes;

  /// 趋势（上升、下降、中性）
  final BarChartTrend trend;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const DarkBarChartCard({
    super.key,
    required this.durationInMinutes,
    this.trend = BarChartTrend.neutral,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例
  factory DarkBarChartCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 将字符串趋势转换为枚举
    BarChartTrend parseTrend(dynamic trendValue) {
      if (trendValue == null) return BarChartTrend.neutral;
      if (trendValue is BarChartTrend) return trendValue;
      if (trendValue is String) {
        switch (trendValue.toLowerCase()) {
          case 'up':
            return BarChartTrend.up;
          case 'down':
            return BarChartTrend.down;
          default:
            return BarChartTrend.neutral;
        }
      }
      return BarChartTrend.neutral;
    }

    return DarkBarChartCard(
      durationInMinutes: props['durationInMinutes'] as int? ?? 0,
      trend: parseTrend(props['trend']),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<DarkBarChartCard> createState() =>
      _DarkBarChartCardState();
}

class _DarkBarChartCardState extends State<DarkBarChartCard>
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
    final backgroundColor = const Color(0xFF4B006E); // 深紫色背景（保持原型设计）
    final barColor = const Color(0xFFC084FC); // 浅紫色柱状条
    final iconBgColor = const Color(0xFFA855F7); // 图标背景色

    final hours = widget.durationInMinutes ~/ 60;
    final minutes = widget.durationInMinutes % 60;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              height: widget.inline ? double.maxFinite : 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 左上角图标
                  Positioned(
                    top: widget.size.getPadding().top,
                    left: widget.size.getPadding().left,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBgColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bed,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                  // 右侧柱状条（睡眠周期可视化）
                  Positioned(
                    top: 16,
                    right: 0,
                    bottom: 16,
                    child: _buildSleepCycles(barColor),
                  ),

                  // 左下角睡眠时长显示
                  Positioned(
                    bottom: widget.size.getPadding().bottom,
                    left: widget.size.getPadding().left,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题
                        Text(
                          'TIME ASLEEP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: const Color(0xFFD8B4FE).withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: widget.size.getItemSpacing()),

                        // 时长显示 + 趋势图标
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 54,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 小时数
                                  SizedBox(
                                    width: 70,
                                    height: 52,
                                    child: AnimatedFlipCounter(
                                      value: hours * _animation.value,
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  // 单位 "h"
                                  SizedBox(
                                    height: 22,
                                    child: Text(
                                      'h',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: widget.size.getItemSpacing()),
                                  // 分钟数
                                  SizedBox(
                                    width: 70,
                                    height: 52,
                                    child: AnimatedFlipCounter(
                                      value: minutes * _animation.value,
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  // 单位 "m"
                                  SizedBox(
                                    height: 22,
                                    child: Text(
                                      'm',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: widget.size.getItemSpacing()),
                            // 趋势图标
                            if (widget.trend != BarChartTrend.neutral)
                              Transform.rotate(
                                angle: widget.trend == BarChartTrend.up
                                    ? 0.78
                                    : -0.78, // 45度旋转
                                child: Icon(
                                  widget.trend == BarChartTrend.up
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: const Color(0xFFD8B4FE),
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建睡眠周期柱状条
  Widget _buildSleepCycles(Color barColor) {
    // 模拟睡眠周期的不同宽度（从原型中提取的数据）
    final cycleWidths = [
      0.80, 0.95, 0.90, 0.98, 0.85, 0.75, 0.90, 0.96, 0.80,
      0.60, 0.45, 0.70, 0.40, 0.35, 0.50, 0.45,
    ];

    return SizedBox(
      width: 140, // 右侧区域宽度
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < cycleWidths.length; i++)
            _buildCycleBar(cycleWidths[i], barColor, i),
        ],
      ),
    );
  }

  /// 构建单个睡眠周期柱状条
  Widget _buildCycleBar(double widthRatio, Color color, int index) {
    // 计算每个柱状条的动画延迟
    // 16个元素，baseEnd = 0.6
    // step <= (1.0 - 0.6) / 15 = 0.0267
    final safeStep = 0.025;
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * safeStep,
        0.6 + index * safeStep,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.size.getItemSpacing() * (1 - itemAnimation.value), 0),
          child: Opacity(
            opacity: 0.9 * itemAnimation.value,
            child: Container(
              height: 16,
              width: 100 * widthRatio,
              margin: EdgeInsets.only(right: widget.size.getItemSpacing()),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
