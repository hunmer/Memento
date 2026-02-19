import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 垂直柱状图小组件
///
/// 用于显示垂直柱状图，支持单系列和多系列数据展示，
/// 每个柱形独立动画，适用于统计、对比、趋势分析等场景。
///
/// 特性：
/// - 单系列或多系列数据展示
/// - 入场动画（渐入+向上位移）
/// - 独立柱形延迟动画
/// - 深色模式适配
/// - 可配置颜色
/// - 支持数值标签显示
/// - 支持自定义X轴标签
///
/// 示例用法：
/// ```dart
/// // 单系列数据
/// VerticalBarChartWidget(
///   title: '月度销售',
///   subtitle: '2024年销售数据统计',
///   value: 12850,
///   valuePrefix: '¥',
///   data: [
///     BarData(label: '1月', value: 85),
///     BarData(label: '2月', value: 92),
///     BarData(label: '3月', value: 78),
///   ],
///   primaryColor: Color(0xFF3B82F6),
/// )
///
/// // 多系列数据
/// VerticalBarChartWidget(
///   title: '季度对比',
///   subtitle: '2023 vs 2024',
///   data: [
///     BarData(label: 'Q1', values: [120, 145]),
///     BarData(label: 'Q2', values: [98, 112]),
///   ],
///   seriesLabels: ['2023', '2024'],
///   primaryColor: Color(0xFF3B82F6),
///   secondaryColor: Color(0xFF10B981),
/// )
/// ```
class VerticalBarChartWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 卡片副标题
  final String subtitle;

  /// 总数值（用于卡片顶部显示）
  final double? value;

  /// 数值前缀
  final String? valuePrefix;

  /// 数值后缀
  final String? valueSuffix;

  /// 柱状图数据
  final List<BarData> data;

  /// 主色调（单系列或多系列第一组）
  final Color? primaryColor;

  /// 次要色调（多系列第二组）
  final Color? secondaryColor;

  /// 第三色调（多系列第三组）
  final Color? tertiaryColor;

  /// 系列标签（多系列时使用）
  final List<String>? seriesLabels;

  /// 是否显示数值标签
  final bool showValueLabels;

  /// 是否显示X轴标签
  final bool showXLabels;

  /// 卡片宽度
  final double? width;

  /// 卡片高度
  final double? height;

  /// 柱形宽度比例 (0.0-1.0)
  final double barWidthRatio;

  /// 柱形间距
  final double barSpacing;

  /// 菜单按钮点击回调
  final VoidCallback? onMenuPressed;

  const VerticalBarChartWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.value,
    this.valuePrefix,
    this.valueSuffix,
    required this.data,
    this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.seriesLabels,
    this.showValueLabels = true,
    this.showXLabels = true,
    this.width,
    this.height,
    this.barWidthRatio = 0.6,
    this.barSpacing = 8.0,
    this.onMenuPressed,
  });

  @override
  State<VerticalBarChartWidget> createState() => _VerticalBarChartWidgetState();
}

class _VerticalBarChartWidgetState extends State<VerticalBarChartWidget>
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

    // 颜色定义（适配主题）
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    // 柱状图颜色
    final barPrimaryColor = widget.primaryColor ??
        (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9));
    final barSecondaryColor = widget.secondaryColor ??
        (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981));
    final barTertiaryColor = widget.tertiaryColor ??
        (isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.width ?? 320,
              height: widget.height ?? 360,
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    _buildTitleRow(context, titleColor, barPrimaryColor),
                    const SizedBox(height: 16),
                    // 总数值（可选）
                    if (widget.value != null) _buildValueDisplay(barPrimaryColor),
                    if (widget.value != null) const SizedBox(height: 16),
                    // 副标题
                    _buildSubtitle(subtitleColor),
                    const SizedBox(height: 8),
                    // 系列图例（多系列时）
                    if (_isMultiSeries()) _buildLegend(barPrimaryColor, barSecondaryColor, barTertiaryColor),
                    if (_isMultiSeries()) const SizedBox(height: 16),
                    // 柱状图
                    Expanded(
                      child: _buildBars(barPrimaryColor, barSecondaryColor, barTertiaryColor),
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

  /// 构建标题行
  Widget _buildTitleRow(BuildContext context, Color titleColor, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 柱状图图标
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        // 菜单按钮
        if (widget.onMenuPressed != null)
          _MenuButton(
            isDark: isDark,
            onPressed: widget.onMenuPressed,
          ),
      ],
    );
  }

  /// 构建总数值显示
  Widget _buildValueDisplay(Color primaryColor) {
    return AnimatedFlipCounter(
      value: widget.value! * _animation.value,
      fractionDigits: widget.value! % 1 != 0 ? 2 : 0,
      prefix: widget.valuePrefix ?? '',
      suffix: widget.valueSuffix ?? '',
      textStyle: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: -1,
      ),
    );
  }

  /// 构建副标题
  Widget _buildSubtitle(Color subtitleColor) {
    return Text(
      widget.subtitle,
      style: TextStyle(
        fontSize: 14,
        color: subtitleColor,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建系列图例
  Widget _buildLegend(Color primaryColor, Color secondaryColor, Color tertiaryColor) {
    final seriesCount = _getSeriesCount();
    final colors = [primaryColor, secondaryColor, tertiaryColor];
    final labels = widget.seriesLabels ?? ['系列1', '系列2', '系列3'];

    return Row(
      children: List.generate(seriesCount, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < seriesCount - 1 ? 16 : 0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors[index],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 构建柱状图区域
  Widget _buildBars(Color primaryColor, Color secondaryColor, Color tertiaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算最大值用于归一化
        final maxValue = _getMaxValue();
        final colors = [primaryColor, secondaryColor, tertiaryColor];
        final seriesCount = _getSeriesCount();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.data.length, (index) {
            final barData = widget.data[index];

            // 为每个柱形创建延迟动画
            final step = 0.05;
            final start = index * step;
            final end = (0.6 + index * step).clamp(0.0, 1.0);
            final barAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                start,
                end,
                curve: Curves.easeOutCubic,
              ),
            );

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.barSpacing / 2),
                child: _BarGroup(
                  data: barData,
                  animation: barAnimation,
                  colors: colors,
                  seriesCount: seriesCount,
                  maxValue: maxValue,
                  maxHeight: constraints.maxHeight,
                  barWidthRatio: widget.barWidthRatio,
                  showValueLabel: widget.showValueLabels,
                  showXLabel: widget.showXLabels,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// 判断是否为多系列数据
  bool _isMultiSeries() {
    return widget.data.any((d) => d.values != null && d.values!.length > 1);
  }

  /// 获取系列数量
  int _getSeriesCount() {
    if (widget.data.isEmpty) return 1;
    return widget.data.first.values?.length ?? 1;
  }

  /// 获取所有数据中的最大值
  double _getMaxValue() {
    double max = 0;
    for (final barData in widget.data) {
      if (barData.values != null) {
        for (final value in barData.values!) {
          if (value > max) max = value;
        }
      } else if (barData.value != null) {
        if (barData.value! > max) max = barData.value!;
      }
    }
    return max > 0 ? max : 100;
  }
}

/// 菜单按钮
class _MenuButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onPressed;

  const _MenuButton({
    required this.isDark,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            Icons.more_vert,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// 柱形组（支持多系列）
class _BarGroup extends StatelessWidget {
  final BarData data;
  final Animation<double> animation;
  final List<Color> colors;
  final int seriesCount;
  final double maxValue;
  final double maxHeight;
  final double barWidthRatio;
  final bool showValueLabel;
  final bool showXLabel;

  const _BarGroup({
    required this.data,
    required this.animation,
    required this.colors,
    required this.seriesCount,
    required this.maxValue,
    required this.maxHeight,
    required this.barWidthRatio,
    required this.showValueLabel,
    required this.showXLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 柱形区域
            SizedBox(
              height: maxHeight - (showXLabel ? 20 : 0) - (showValueLabel && seriesCount == 1 ? 20 : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildBars(isDark, textColor),
              ),
            ),
            // 数值标签（仅单系列时显示在柱形上方）
            if (showValueLabel && seriesCount == 1 && data.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatValue(data.value!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            // X轴标签
            if (showXLabel)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }

  /// 构建单个或多个柱形
  List<Widget> _buildBars(bool isDark, Color textColor) {
    final values = data.values ?? (data.value != null ? [data.value!] : [0]);
    final barHeight = (maxHeight - (showXLabel ? 20 : 0)) * 0.8;
    final barWidth = (barHeight * barWidthRatio) / seriesCount;

    return List.generate(seriesCount, (index) {
      final value = index < values.length ? values[index] : 0.0;
      final height = (value / maxValue) * barHeight * animation.value;

      return Padding(
        padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 数值标签（多系列时显示在柱形上方）
            if (showValueLabel && seriesCount > 1 && index < values.length)
              Text(
                _formatValue(values[index]),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors[index % colors.length],
                ),
              ),
            if (showValueLabel && seriesCount > 1) const SizedBox(height: 2),
            // 柱形
            Container(
              width: barWidth,
              height: height,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 格式化数值显示
  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }
}

/// 柱状图数据模型
///
/// 表示单个X轴位置的一个或多个柱形数据。
class BarData {
  /// X轴标签
  final String label;

  /// 单系列数值
  final double? value;

  /// 多系列数值列表
  final List<double>? values;

  const BarData({
    required this.label,
    this.value,
    this.values,
  }) : assert(value != null || values != null, 'Either value or values must be provided');

  /// 创建单系列数据
  factory BarData.single({
    required String label,
    required double value,
  }) {
    return BarData(label: label, value: value);
  }

  /// 创建多系列数据
  factory BarData.multiple({
    required String label,
    required List<double> values,
  }) {
    return BarData(label: label, values: values);
  }
}
