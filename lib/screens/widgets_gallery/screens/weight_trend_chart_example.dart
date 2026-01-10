import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:fl_chart/fl_chart.dart';

/// 体重趋势图表示例
class WeightTrendChartExample extends StatelessWidget {
  const WeightTrendChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('体重趋势图表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF9FAFB),
        child: const Center(
          child: WeightTrendChartWidget(
            currentWeight: 67.8,
            weightStatus: 'You\'re on a normal weight range',
            dataPoints: [
              WeightDataPoint(day: '12', value: 68.2),
              WeightDataPoint(day: '13', value: 67.5),
              WeightDataPoint(day: '14', value: 67.8),
              WeightDataPoint(day: '15', value: 66.9),
              WeightDataPoint(day: '16', value: 68.0),
              WeightDataPoint(day: '17', value: 67.5),
              WeightDataPoint(day: '18', value: 67.3),
              WeightDataPoint(day: '19', value: 68.5),
              WeightDataPoint(day: '20', value: 67.8),
              WeightDataPoint(day: '21', value: 67.6),
              WeightDataPoint(day: '22', value: 67.2),
              WeightDataPoint(day: '23', value: 67.8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 体重数据点模型
class WeightDataPoint {
  final String day;
  final double value;

  const WeightDataPoint({required this.day, required this.value});
}

/// 体重趋势图表小组件
class WeightTrendChartWidget extends StatefulWidget {
  final double currentWeight;
  final String weightStatus;
  final List<WeightDataPoint> dataPoints;

  const WeightTrendChartWidget({
    super.key,
    required this.currentWeight,
    required this.weightStatus,
    required this.dataPoints,
  });

  @override
  State<WeightTrendChartWidget> createState() => _WeightTrendChartWidgetState();
}

class _WeightTrendChartWidgetState extends State<WeightTrendChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedTabIndex = 4; // 默认选中 "All Time"

  final List<String> _timeFilters = ['1d', '1w', '1m', '1y', 'All Time'];

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
    final textColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);
    final mutedColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final tabBackgroundColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    final activeTabColor = isDark ? const Color(0xFF4B5563) : Colors.white;

    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // 主内容区
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _animation.value)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // 体重数值显示区
                          _buildWeightDisplay(
                            isDark,
                            primaryColor,
                            textColor,
                            mutedColor,
                          ),

                          const SizedBox(height: 32),

                          // 时间范围筛选标签
                          _buildTimeFilterTabs(
                            isDark,
                            tabBackgroundColor,
                            activeTabColor,
                            textColor,
                            mutedColor,
                            primaryColor,
                          ),

                          const SizedBox(height: 32),

                          // 图表区域
                          _buildChart(isDark, primaryColor, mutedColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 体重数值显示区
  Widget _buildWeightDisplay(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.monitor_weight, color: Colors.white, size: 20),
            ),

            const SizedBox(width: 12),

            // 体重数值
            SizedBox(
              height: 58,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 52,
                    child: AnimatedFlipCounter(
                      value: widget.currentWeight * _animation.value,
                      fractionDigits: 1,
                      textStyle: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    child: Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 状态文本
        Text(
          widget.weightStatus,
          style: TextStyle(fontSize: 14, color: mutedColor),
        ),
      ],
    );
  }

  /// 时间范围筛选标签
  Widget _buildTimeFilterTabs(
    bool isDark,
    Color tabBackgroundColor,
    Color activeTabColor,
    Color textColor,
    Color mutedColor,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_timeFilters.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeTabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  _timeFilters[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? textColor : mutedColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 图表区域
  Widget _buildChart(bool isDark, Color primaryColor, Color mutedColor) {
    // 计算最小和最大值以设置 Y 轴范围
    final values = widget.dataPoints.map((p) => p.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxValue = values.reduce((a, b) => a > b ? a : b) + 0.5;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // 图表
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    verticalInterval: 35,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: mutedColor.withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: mutedColor.withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 0,
                        interval: 35,
                        getTitlesWidget: (value, meta) {
                          final index = value ~/ 35;
                          if (index >= 0 && index < widget.dataPoints.length) {
                            return Text(
                              widget.dataPoints[index].day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (widget.dataPoints.length - 1) * 35.0,
                  minY: minValue,
                  maxY: maxValue,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        widget.dataPoints.length,
                        (index) => FlSpot(
                          index * 35.0,
                          widget.dataPoints[index].value,
                        ),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: primaryColor,
                            strokeWidth: 3,
                            strokeColor:
                                isDark ? const Color(0xFF111827) : Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primaryColor.withOpacity(0.1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor.withOpacity(0.3),
                            primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor:
                          isDark ? const Color(0xFF1F2937) : Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = (spot.x / 35).round();
                          if (index >= 0 && index < widget.dataPoints.length) {
                            return LineTooltipItem(
                              '${widget.dataPoints[index].value} kg',
                              TextStyle(
                                color:
                                    isDark
                                        ? const Color(0xFFF3F4F6)
                                        : const Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),

            // X 轴标签
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    widget.dataPoints.map((point) {
                      return SizedBox(
                        width: 24,
                        child: Text(
                          point.day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: mutedColor,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
