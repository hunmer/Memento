import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 性能指标柱状图示例
class PerformanceBarChartExample extends StatelessWidget {
  const PerformanceBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('性能指标柱状图')),
      body: Container(
        color: isDark ? const Color(0xFF132e27) : const Color(0xFFF0F2F5),
        child: const Center(
          child: PerformanceBarChartWidget(
            badgeLabel: 'Performance',
            growthPercentage: 280,
            timePeriod: 'In the past 30 days',
            barData: [
              BarData(value: 12, label: '12%'),
              BarData(value: 78, label: '78%'),
              BarData(value: 62, label: '62%'),
              BarData(value: 70, label: '70%'),
              BarData(value: 75, label: '75%'),
              BarData(value: 95, label: '95%'),
            ],
            footerLabel: 'See All',
          ),
        ),
      ),
    );
  }
}

/// 柱状图数据模型
class BarData {
  final double value;
  final String label;

  const BarData({
    required this.value,
    required this.label,
  });
}

/// 性能指标柱状图小组件
class PerformanceBarChartWidget extends StatefulWidget {
  final String badgeLabel;
  final double growthPercentage;
  final String timePeriod;
  final List<BarData> barData;
  final String footerLabel;

  const PerformanceBarChartWidget({
    super.key,
    required this.badgeLabel,
    required this.growthPercentage,
    required this.timePeriod,
    required this.barData,
    required this.footerLabel,
  });

  @override
  State<PerformanceBarChartWidget> createState() => _PerformanceBarChartWidgetState();
}

class _PerformanceBarChartWidgetState extends State<PerformanceBarChartWidget>
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
    final primaryColor = const Color(0xFF7c71f5);
    final accentLime = const Color(0xFFdcfeb6);
    final accentPeach = const Color(0xFFffdba5);
    final gridColor = isDark ? const Color(0xFF27272a) : const Color(0xFFe5e7eb);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              height: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181b) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标签和增长数据
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentPeach,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.badgeLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedFlipCounter(
                            value: widget.growthPercentage * _animation.value,
                            fractionDigits: 0,
                            prefix: '+',
                            suffix: '%',
                            duration: const Duration(milliseconds: 1000),
                            textStyle: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.grey.shade900,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.timePeriod,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // 柱状图区域
                  SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        // 背景网格线
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              4,
                              (index) => Container(
                                height: 1,
                                color: gridColor,
                              ),
                            ),
                          ),
                        ),
                        // 柱状图
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                widget.barData.length,
                                (index) {
                                  final bar = widget.barData[index];
                                  final barAnimation = CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index * 0.1,
                                      0.6 + index * 0.08,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: _AnimatedBar(
                                        value: bar.value,
                                        label: bar.label,
                                        primaryColor: primaryColor,
                                        accentLime: accentLime,
                                        animation: barAnimation,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 底部查看全部
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.footerLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.5,
                          ),
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
}

/// 单个柱状图条目（带动画）
class _AnimatedBar extends StatelessWidget {
  final double value;
  final String label;
  final Color primaryColor;
  final Color accentLime;
  final Animation<double> animation;

  const _AnimatedBar({
    required this.value,
    required this.label,
    required this.primaryColor,
    required this.accentLime,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = value * animation.value;
        final showLabel = animation.value > 0.5;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 柱子主体
                  Container(
                    width: double.infinity,
                    height: 180 * animatedValue / 100,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentLime,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (showLabel)
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Opacity(
                              opacity: (animation.value - 0.5) * 2,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
