import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 平滑折线图卡片示例
class SmoothLineChartCardExample extends StatelessWidget {
  const SmoothLineChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('平滑折线图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        child: const Center(
          child: SmoothLineChartCardWidget(
            title: 'Monthly Average\nRainfall',
            subtitle: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
            data: [12, 15, 13, 18, 14, 25, 22, 28, 20, 32, 28, 26, 35, 30, 38],
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'],
          ),
        ),
      ),
    );
  }
}

/// 平滑折线图小组件
class SmoothLineChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<double> data;
  final List<String> labels;

  const SmoothLineChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.labels,
  });

  @override
  State<SmoothLineChartCardWidget> createState() => _SmoothLineChartCardWidgetState();
}

class _SmoothLineChartCardWidgetState extends State<SmoothLineChartCardWidget>
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
    final primaryColor = const Color(0xFF0EA5E9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              height: 340,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            _ShareButton(isDark: isDark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        // 折线图
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (widget.data.length - 1).toDouble(),
                              minY: 0,
                              maxY: 50,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    widget.data.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      widget.data[index],
                                    ),
                                  ),
                                  isCurved: true,
                                  color: primaryColor,
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: primaryColor,
                                        strokeWidth: 2,
                                        strokeColor: backgroundColor,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        primaryColor.withOpacity(0.2 * _animation.value),
                                        primaryColor.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              lineTouchData: const LineTouchData(enabled: false),
                            ),
                          ),
                        ),
                        // 底部渐变遮罩
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  backgroundColor.withOpacity(0),
                                  backgroundColor,
                                ],
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
          ),
        );
      },
    );
  }
}

/// 分享按钮组件
class _ShareButton extends StatelessWidget {
  final bool isDark;

  const _ShareButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.share,
        size: 20,
        color: Color(0xFF6B7280),
      ),
    );
  }
}
