import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 双范围图表统计卡片示例
class DualRangeChartCardExample extends StatelessWidget {
  const DualRangeChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('双范围图表统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: DualRangeChartCardWidget(
            date: 'Jan 12, 2028',
            weekDays: ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'],
            ranges: [
              DualRangeData(
                day: 'Wed',
                primaryRange: RangeData(min: 130, max: 145, startPercent: 0.15, heightPercent: 0.25),
                secondaryRange: RangeData(min: 75, max: 85, startPercent: 0.55, heightPercent: 0.15),
              ),
              DualRangeData(
                day: 'Thu',
                primaryRange: RangeData(min: 125, max: 150, startPercent: 0.20, heightPercent: 0.40),
                secondaryRange: RangeData(min: 78, max: 88, startPercent: 0.65, heightPercent: 0.25),
              ),
              DualRangeData(
                day: 'Fri',
                primaryRange: RangeData(min: 135, max: 142, startPercent: 0.10, heightPercent: 0.20),
                secondaryRange: RangeData(min: 72, max: 80, startPercent: 0.50, heightPercent: 0.18),
              ),
              DualRangeData(
                day: 'Sat',
                primaryRange: RangeData(min: 128, max: 138, startPercent: 0.25, heightPercent: 0.15),
                secondaryRange: RangeData(min: 76, max: 82, startPercent: 0.58, heightPercent: 0.10),
              ),
              DualRangeData(
                day: 'Sun',
                primaryRange: RangeData(min: 122, max: 140, startPercent: 0.18, heightPercent: 0.30),
                secondaryRange: RangeData(min: 74, max: 81, startPercent: 0.60, heightPercent: 0.12),
              ),
              DualRangeData(
                day: 'Mon',
                primaryRange: RangeData(min: 132, max: 148, startPercent: 0.22, heightPercent: 0.35),
                secondaryRange: RangeData(min: 77, max: 85, startPercent: 0.65, heightPercent: 0.15),
              ),
              DualRangeData(
                day: 'Tue',
                primaryRange: RangeData(min: 126, max: 141, startPercent: 0.10, heightPercent: 0.28),
                secondaryRange: RangeData(min: 73, max: 86, startPercent: 0.50, heightPercent: 0.22),
              ),
            ],
            primarySummary: RangeSummary(min: 129, max: 141, label: 'sys'),
            secondarySummary: RangeSummary(min: 70, max: 99, label: 'mmHg'),
          ),
        ),
      ),
    );
  }
}

/// 范围数据模型
class RangeData {
  final double min;
  final double max;
  final double startPercent;
  final double heightPercent;

  const RangeData({
    required this.min,
    required this.max,
    required this.startPercent,
    required this.heightPercent,
  });
}

/// 双范围数据模型（每日数据）
class DualRangeData {
  final String day;
  final RangeData primaryRange;
  final RangeData secondaryRange;

  const DualRangeData({
    required this.day,
    required this.primaryRange,
    required this.secondaryRange,
  });
}

/// 范围汇总数据
class RangeSummary {
  final int min;
  final int max;
  final String label;

  const RangeSummary({
    required this.min,
    required this.max,
    required this.label,
  });
}

/// 双范围图表统计小组件
class DualRangeChartCardWidget extends StatefulWidget {
  final String date;
  final List<String> weekDays;
  final List<DualRangeData> ranges;
  final RangeSummary primarySummary;
  final RangeSummary secondarySummary;

  const DualRangeChartCardWidget({
    super.key,
    required this.date,
    required this.weekDays,
    required this.ranges,
    required this.primarySummary,
    required this.secondarySummary,
  });

  @override
  State<DualRangeChartCardWidget> createState() => _DualRangeChartCardWidgetState();
}

class _DualRangeChartCardWidgetState extends State<DualRangeChartCardWidget>
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
    final gridColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.grey.shade800;
    final mutedColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = isDark
        ? primaryColor.withOpacity(0.3)
        : primaryColor.withOpacity(0.2);
    final secondaryColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final secondaryLight = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 日期选择器
                  _buildDateSelector(context, isDark, textColor),
                  const SizedBox(height: 32),

                  // 图表区域
                  _buildChart(
                    context,
                    gridColor,
                    primaryColor,
                    primaryLight,
                    secondaryColor,
                    secondaryLight,
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  // 汇总数据
                  _buildSummary(
                    context,
                    primaryColor,
                    secondaryColor,
                    textColor,
                    mutedColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavButton(context, Icons.chevron_left, isDark, textColor),
        Text(
          widget.date,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        _buildNavButton(context, Icons.chevron_right, isDark, textColor),
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, IconData icon, bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700.withOpacity(0.3) : Colors.grey.shade100.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: textColor),
        onPressed: () {},
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    Color gridColor,
    Color primaryColor,
    Color primaryLight,
    Color secondaryColor,
    Color secondaryLight,
  ) {
    return SizedBox(
      height: 256,
      child: Stack(
        children: [
          // 背景网格
          _buildGridLines(gridColor),
          // 数据柱状图
          ...widget.ranges.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            // 计算安全的 step 值，确保最大 end 值不超过 1.0
            // 7 个元素，step <= (1.0 - 0.6) / 6 = 0.066
            final step = 0.06;
            final itemAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * step,
                0.6 + index * step,
                curve: Curves.easeOutCubic,
              ),
            );
            return _RangeBar(
              data: data,
              primaryColor: primaryColor,
              primaryLight: primaryLight,
              secondaryColor: secondaryColor,
              secondaryLight: secondaryLight,
              animation: itemAnimation,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGridLines(Color color) {
    return Column(
      children: [
        ...List.generate(
          4,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: 1, style: BorderStyle.solid),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryItem(
          context,
          primaryColor,
          '${widget.primarySummary.min}-${widget.primarySummary.max}',
          widget.primarySummary.label,
          textColor,
          mutedColor,
        ),
        _buildSummaryItem(
          context,
          secondaryColor,
          '${widget.secondarySummary.min}-${widget.secondarySummary.max}',
          widget.secondarySummary.label,
          textColor,
          mutedColor,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    Color color,
    String value,
    String label,
    Color textColor,
    Color mutedColor,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 30,
              child: AnimatedFlipCounter(
                value: double.parse(value.split('-')[0]) * _animation.value,
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.0,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 范围柱状图组件
class _RangeBar extends StatelessWidget {
  final DualRangeData data;
  final Color primaryColor;
  final Color primaryLight;
  final Color secondaryColor;
  final Color secondaryLight;
  final Animation<double> animation;

  const _RangeBar({
    required this.data,
    required this.primaryColor,
    required this.primaryLight,
    required this.secondaryColor,
    required this.secondaryLight,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // 计算当前柱子的位置索引
    final dayIndex = data.day == 'Wed' ? 0 : data.day == 'Thu' ? 1 : data.day == 'Fri' ? 2 : data.day == 'Sat' ? 3 : data.day == 'Sun' ? 4 : data.day == 'Mon' ? 5 : 6;

    return Positioned(
      left: dayIndex * 48.0,
      child: SizedBox(
        width: 12,
        height: 256,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Primary Range Bar
            Positioned(
              top: data.primaryRange.startPercent * 256,
              left: 0,
              right: 0,
              height: data.primaryRange.heightPercent * 256 * animation.value,
              child: Column(
                children: [
                  Container(
                    height: 6,
                    color: primaryColor,
                  ),
                  Expanded(
                    child: Container(
                      color: primaryLight.withOpacity(0.8),
                    ),
                  ),
                  Container(
                    height: 6,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
            // Secondary Range Bar
            Positioned(
              top: data.secondaryRange.startPercent * 256,
              left: 0,
              right: 0,
              height: data.secondaryRange.heightPercent * 256 * animation.value,
              child: Column(
                children: [
                  Container(
                    height: 6,
                    color: secondaryColor,
                  ),
                  Expanded(
                    child: Container(
                      color: secondaryLight.withOpacity(0.8),
                    ),
                  ),
                  Container(
                    height: 6,
                    color: secondaryColor,
                  ),
                ],
              ),
            ),
            // Day Label (positioned below the chart)
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  data.day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade500
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
