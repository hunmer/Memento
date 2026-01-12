import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 范围数据模型
class DualRangeValue {
  final double min;
  final double max;
  final double startPercent;
  final double heightPercent;

  const DualRangeValue({
    required this.min,
    required this.max,
    required this.startPercent,
    required this.heightPercent,
  });
}

/// 双范围数据模型（每日数据）
class DualRangeDayData {
  final String label;
  final DualRangeValue primaryRange;
  final DualRangeValue secondaryRange;

  const DualRangeDayData({
    required this.label,
    required this.primaryRange,
    required this.secondaryRange,
  });
}

/// 范围汇总数据
class DualRangeSummary {
  final int min;
  final int max;
  final String label;

  const DualRangeSummary({
    required this.min,
    required this.max,
    required this.label,
  });
}

/// 双范围图表统计卡片
///
/// 用于展示双数值范围周统计数据的卡片组件，支持动画效果和主题适配。
/// 适用于展示血压、温度、双指标数据等场景，如血压监测（收缩压/舒张压）、
/// 温度范围（最高温/最低温）等。
///
/// 使用示例：
/// ```dart
/// DualRangeChartCard(
///   date: 'Jan 12, 2028',
///   labels: ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'],
///   data: [
///     DualRangeDayData(
///       label: 'Wed',
///       primaryRange: DualRangeValue(
///         min: 130, max: 145, startPercent: 0.15, heightPercent: 0.25,
///       ),
///       secondaryRange: DualRangeValue(
///         min: 75, max: 85, startPercent: 0.55, heightPercent: 0.15,
///       ),
///     ),
///     // ... 更多数据
///   ],
///   primarySummary: DualRangeSummary(min: 129, max: 141, label: 'sys'),
///   secondarySummary: DualRangeSummary(min: 70, max: 99, label: 'mmHg'),
///   onPreviousDate: () => print('Previous'),
///   onNextDate: () => print('Next'),
/// )
/// ```
class DualRangeChartCard extends StatefulWidget {
  /// 当前日期显示
  final String date;

  /// 数据标签列表（如星期几）
  final List<String> labels;

  /// 每日双范围数据
  final List<DualRangeDayData> data;

  /// 主范围汇总数据
  final DualRangeSummary primarySummary;

  /// 次范围汇总数据
  final DualRangeSummary secondarySummary;

  /// 前一天回调
  final VoidCallback? onPreviousDate;

  /// 后一天回调
  final VoidCallback? onNextDate;

  const DualRangeChartCard({
    super.key,
    required this.date,
    required this.labels,
    required this.data,
    required this.primarySummary,
    required this.secondarySummary,
    this.onPreviousDate,
    this.onNextDate,
  });

  @override
  State<DualRangeChartCard> createState() => _DualRangeChartCardState();
}

class _DualRangeChartCardState extends State<DualRangeChartCard>
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
                  const SizedBox(height: 48),

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
        _buildNavButton(
          context,
          Icons.chevron_left,
          isDark,
          textColor,
          widget.onPreviousDate,
        ),
        Text(
          widget.date,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        _buildNavButton(
          context,
          Icons.chevron_right,
          isDark,
          textColor,
          widget.onNextDate,
        ),
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    bool isDark,
    Color textColor,
    VoidCallback? onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade700.withOpacity(0.3)
            : Colors.grey.shade100.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: textColor),
        onPressed: onPressed,
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
          ...widget.data.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
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
    final minValue = double.tryParse(value.split('-')[0]) ?? 0.0;

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
                value: minValue * _animation.value,
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
  final DualRangeDayData data;
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
    final labelIndex = data.label == 'Wed'
        ? 0
        : data.label == 'Thu'
            ? 1
            : data.label == 'Fri'
                ? 2
                : data.label == 'Sat'
                    ? 3
                    : data.label == 'Sun'
                        ? 4
                        : data.label == 'Mon'
                            ? 5
                            : 6;

    return Positioned(
      left: labelIndex * 48.0,
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
                  data.label,
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
