import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 周条形图卡片示例
class WeeklyBarChartCardExample extends StatelessWidget {
  const WeeklyBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('周条形图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F8),
        child: const Center(
          child: WeeklyBarChartCardWidget(
            title: 'Transactions',
            subtitle: 'vs last month',
            percentage: 54,
            weeklyData: [
              WeeklyBarData(label: 'Mon', upperHeight: 0.40, lowerHeight: 0.35),
              WeeklyBarData(label: 'Tue', upperHeight: 0.30, lowerHeight: 0.55),
              WeeklyBarData(label: 'Wed', upperHeight: 0.25, lowerHeight: 0.35),
              WeeklyBarData(label: 'Thu', upperHeight: 0.20, lowerHeight: 0.48),
              WeeklyBarData(label: 'Fri', upperHeight: 0.20, lowerHeight: 0.60),
              WeeklyBarData(label: 'Sat', upperHeight: 0.15, lowerHeight: 0.25),
              WeeklyBarData(label: 'Sun', upperHeight: 0.30, lowerHeight: 0.45),
            ],
          ),
        ),
      ),
    );
  }
}

/// 周条形数据
class WeeklyBarData {
  final String label;
  final double upperHeight;
  final double lowerHeight;

  const WeeklyBarData({
    required this.label,
    required this.upperHeight,
    required this.lowerHeight,
  });
}

/// 周条形图小组件
class WeeklyBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int percentage;
  final List<WeeklyBarData> weeklyData;

  const WeeklyBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.weeklyData,
  });

  @override
  State<WeeklyBarChartCardWidget> createState() => _WeeklyBarChartCardWidgetState();
}

class _WeeklyBarChartCardWidgetState extends State<WeeklyBarChartCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 400,
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // 条形图区域
                    SizedBox(
                      height: 192,
                      child: _WeeklyBars(
                        data: widget.weeklyData,
                        animation: _animation,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 底部信息
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  AnimatedFlipCounter(
                                    value: widget.percentage.toDouble() * _animation.value,
                                    fractionDigits: 0,
                                    suffix: '%',
                                    textStyle: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? primaryColor.withOpacity(0.2)
                                          : const Color(0xFFBFDBFE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.subtitle,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

/// 周条形图组件
class _WeeklyBars extends StatelessWidget {
  final List<WeeklyBarData> data;
  final Animation<double> animation;

  const _WeeklyBars({
    required this.data,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final lightColor = isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade200.withOpacity(0.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final item = data[index];
        final barAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * 0.1,
            0.5 + index * 0.1,
            curve: Curves.easeOutCubic,
          ),
        );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < data.length - 1 ? 12 : 0),
            child: Column(
              children: [
                // 条形图容器
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 上层浅色条
                        AnimatedBuilder(
                          animation: barAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 144 * item.upperHeight * barAnimation.value,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: lightColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        // 下层主条
                        AnimatedBuilder(
                          animation: barAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 144 * item.lowerHeight * barAnimation.value,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF4FABFF),
                                    primaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 标签
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
