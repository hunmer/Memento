import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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

  /// 从 JSON 创建
  factory RangeData.fromJson(Map<String, dynamic> json) {
    return RangeData(
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      startPercent: (json['startPercent'] as num?)?.toDouble() ?? 0.0,
      heightPercent: (json['heightPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'startPercent': startPercent,
      'heightPercent': heightPercent,
    };
  }
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

  /// 从 JSON 创建
  factory DualRangeData.fromJson(Map<String, dynamic> json) {
    return DualRangeData(
      day: json['day'] as String? ?? '',
      primaryRange: RangeData.fromJson(
        json['primaryRange'] as Map<String, dynamic>? ?? {},
      ),
      secondaryRange: RangeData.fromJson(
        json['secondaryRange'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'primaryRange': primaryRange.toJson(),
      'secondaryRange': secondaryRange.toJson(),
    };
  }
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

  /// 从 JSON 创建
  factory RangeSummary.fromJson(Map<String, dynamic> json) {
    return RangeSummary(
      min: json['min'] as int? ?? 0,
      max: json['max'] as int? ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max, 'label': label};
  }
}

/// 双范围图表统计小组件
class DualRangeChartCardWidget extends StatefulWidget {
  final String date;
  final List<String> weekDays;
  final List<DualRangeData> ranges;
  final RangeSummary primarySummary;
  final RangeSummary secondarySummary;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const DualRangeChartCardWidget({
    super.key,
    required this.date,
    required this.weekDays,
    required this.ranges,
    required this.primarySummary,
    required this.secondarySummary,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DualRangeChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final rangesList =
        (props['ranges'] as List<dynamic>?)
            ?.map((e) => DualRangeData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final weekDaysList =
        (props['weekDays'] as List<dynamic>?)?.cast<String>() ?? const [];

    return DualRangeChartCardWidget(
      date: props['date'] as String? ?? '',
      weekDays: weekDaysList,
      ranges: rangesList,
      primarySummary: RangeSummary.fromJson(
        props['primarySummary'] as Map<String, dynamic>? ?? {},
      ),
      secondarySummary: RangeSummary.fromJson(
        props['secondarySummary'] as Map<String, dynamic>? ?? {},
      ),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<DualRangeChartCardWidget> createState() =>
      _DualRangeChartCardWidgetState();
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
    final primaryLight =
        isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.2);
    final secondaryColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final secondaryLight = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    // 根据 size 调整的尺寸
    final basePadding = widget.inline ? 12.0 : 10.0;
    final padding = basePadding * widget.size.padding;
    final borderRadius = 20.0 * widget.size.scale;
    final sectionSpacing = 8.0 * widget.size.spacing;
    final bottomSpacing = 10.0 * widget.size.spacing;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * widget.size.scale * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 300 * widget.size.scale,
              height: widget.inline ? double.maxFinite : 320 * widget.size.scale,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Column(
                children: [
                  _buildDateSelector(context, isDark, textColor),
                  SizedBox(height: sectionSpacing),
                  Expanded(
                    child: Center(
                      child: _buildChart(
                        context,
                        gridColor,
                        primaryColor,
                        primaryLight,
                        secondaryColor,
                        secondaryLight,
                      ),
                    ),
                  ),
                  SizedBox(height: bottomSpacing * 1.5),
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

  Widget _buildDateSelector(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    final baseFontSize = widget.inline ? 14.0 : 16.0;
    final fontSize = baseFontSize * widget.size.fontSize;
    final iconSize = 16.0 * widget.size.iconSize;
    final buttonSize = 28.0 * widget.size.scale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavButton(
          context,
          Icons.chevron_left,
          isDark,
          textColor,
          iconSize,
          buttonSize,
        ),
        Flexible(
          child: Text(
            widget.date,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildNavButton(
          context,
          Icons.chevron_right,
          isDark,
          textColor,
          iconSize,
          buttonSize,
        ),
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    bool isDark,
    Color textColor,
    double iconSize,
    double buttonSize,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.grey.shade700.withOpacity(0.3)
                : Colors.grey.shade100.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: textColor, size: iconSize),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        final chartWidth = constraints.maxWidth;

        return Stack(
          children: [
            ...widget.ranges.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final step = 0.06;
              final start = index * step;
              final end = (0.6 + index * step).clamp(0.0, 1.0);
              final itemAnimation = CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  start,
                  end,
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
                size: widget.size,
                chartHeight: chartHeight,
                chartWidth: chartWidth,
                totalCount: widget.ranges.length,
              );
            }),
          ],
        );
      },
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
        Flexible(
          child: _buildSummaryItem(
            context,
            primaryColor,
            '${widget.primarySummary.min}-${widget.primarySummary.max}',
            widget.primarySummary.label,
            textColor,
            mutedColor,
          ),
        ),
        Flexible(
          child: _buildSummaryItem(
            context,
            secondaryColor,
            '${widget.secondarySummary.min}-${widget.secondarySummary.max}',
            widget.secondarySummary.label,
            textColor,
            mutedColor,
          ),
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
    final baseValueFontSize = widget.inline ? 16.0 : 20.0;
    final baseLabelFontSize = widget.inline ? 10.0 : 11.0;
    final valueFontSize = baseValueFontSize * widget.size.fontSize;
    final labelFontSize = baseLabelFontSize * widget.size.fontSize;
    final indicatorWidth = 8.0 * widget.size.scale;
    final indicatorHeight = 5.0 * widget.size.scale;
    final spacing = 4.0 * widget.size.spacing;
    final valueHeight = 16.0 * widget.size.scale;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: indicatorWidth,
          height: indicatorHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(indicatorHeight / 2),
          ),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: valueHeight,
                child: AnimatedFlipCounter(
                  value: double.parse(value.split('-')[0]) * _animation.value,
                  textStyle: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  final DualRangeData data;
  final Color primaryColor;
  final Color primaryLight;
  final Color secondaryColor;
  final Color secondaryLight;
  final Animation<double> animation;
  final HomeWidgetSize size;
  final double chartHeight;
  final double chartWidth;
  final int totalCount;

  const _RangeBar({
    required this.data,
    required this.primaryColor,
    required this.primaryLight,
    required this.secondaryColor,
    required this.secondaryLight,
    required this.animation,
    required this.size,
    required this.chartHeight,
    required this.chartWidth,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final dayIndex =
        data.day == 'Wed'
            ? 0
            : data.day == 'Thu'
            ? 1
            : data.day == 'Fri'
            ? 2
            : data.day == 'Sat'
            ? 3
            : data.day == 'Sun'
            ? 4
            : data.day == 'Mon'
            ? 5
            : 6;

    final strokeWidth = size.getStrokeWidth() * 0.2; // 根据尺寸调整线条粗细
    final dayLabelFontSize = size.getLegendFontSize() * 0.8; // 根据尺寸调整标签字体

    final barSpacing = chartWidth / totalCount; // 基于数据数量计算水平间距
    final barWidth = barSpacing * 0.6; // 条形宽度为间距的 60%，留出间隙

    return Positioned(
      left: dayIndex * barSpacing + (barSpacing - barWidth) / 2,
      child: SizedBox(
        width: barWidth,
        height: chartHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: data.primaryRange.startPercent * (chartHeight - 18),
              left: 0,
              right: 0,
              height:
                  data.primaryRange.heightPercent *
                  (chartHeight - 18) *
                  animation.value,
              child: Column(
                children: [
                  Container(height: strokeWidth, color: primaryColor),
                  Expanded(
                    child: Container(color: primaryLight.withOpacity(0.8)),
                  ),
                  Container(height: strokeWidth, color: primaryColor),
                ],
              ),
            ),
            Positioned(
              top: data.secondaryRange.startPercent * (chartHeight - 18),
              left: 0,
              right: 0,
              height:
                  data.secondaryRange.heightPercent *
                  (chartHeight - 18) *
                  animation.value,
              child: Column(
                children: [
                  Container(height: strokeWidth, color: secondaryColor),
                  Expanded(
                    child: Container(color: secondaryLight.withOpacity(0.8)),
                  ),
                  Container(height: strokeWidth, color: secondaryColor),
                ],
              ),
            ),
            Positioned(
              bottom: -14,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  data.day,
                  style: TextStyle(
                    fontSize: dayLabelFontSize,
                    fontWeight: FontWeight.w500,
                    color:
                        Theme.of(context).brightness == Brightness.dark
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
