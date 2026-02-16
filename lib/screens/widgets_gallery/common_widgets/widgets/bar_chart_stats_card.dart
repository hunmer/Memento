import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 柱状图统计小组件
class BarChartStatsCardWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 日期范围
  final String dateRange;

  /// 平均值
  final double averageValue;

  /// 单位
  final String unit;

  /// 图标
  final IconData icon;

  /// 图标颜色
  final Color iconColor;

  /// 数据点列表
  final List<double> data;

  /// X轴标签列表
  final List<String> labels;

  /// Y轴最大值
  final double maxValue;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const BarChartStatsCardWidget({
    super.key,
    required this.title,
    required this.dateRange,
    required this.averageValue,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.data,
    required this.labels,
    required this.maxValue,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory BarChartStatsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 解析颜色
    Color parseColor(dynamic colorValue) {
      if (colorValue == null) return Colors.blue;
      if (colorValue is Color) return colorValue;
      if (colorValue is int) return Color(colorValue);
      if (colorValue is String) {
        try {
          // 支持十六进制颜色格式
          if (colorValue.startsWith('#')) {
            return Color(
              int.parse(colorValue.substring(1), radix: 16) + 0xFF000000,
            );
          }
          // 支持 0xFF 格式
          if (colorValue.startsWith('0x')) {
            return Color(int.parse(colorValue.substring(2), radix: 16));
          }
        } catch (e) {
          // 解析失败，返回默认颜色
        }
      }
      return Colors.blue;
    }

    return BarChartStatsCardWidget(
      title: props['title'] as String? ?? 'Stats',
      dateRange: props['dateRange'] as String? ?? '',
      averageValue: (props['averageValue'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      icon: _parseIcon(props['icon'] as String?),
      iconColor: parseColor(props['iconColor']),
      data:
          (props['data'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      labels:
          (props['labels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      maxValue: (props['maxValue'] as num?)?.toDouble() ?? 10.0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  /// 解析图标字符串为 IconData
  static IconData _parseIcon(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return Icons.bar_chart;
    }

    // 常用图标映射
    const iconMap = {
      'bar_chart': Icons.bar_chart,
      'directions_run': Icons.directions_run,
      'favorite': Icons.favorite,
      'fitness_center': Icons.fitness_center,
      'local_fire_department': Icons.local_fire_department,
      'water_drop': Icons.water_drop,
      'restaurant': Icons.restaurant,
      'work': Icons.work,
      'school': Icons.school,
      'shopping_cart': Icons.shopping_cart,
      'flight': Icons.flight,
      'bedtime': Icons.bedtime,
      'alarm': Icons.alarm,
      'timer': Icons.timer,
      'schedule': Icons.schedule,
      'event': Icons.event,
    };

    return iconMap[iconString] ?? Icons.bar_chart;
  }

  @override
  State<BarChartStatsCardWidget> createState() =>
      _BarChartStatsCardWidgetState();
}

class _BarChartStatsCardWidgetState extends State<BarChartStatsCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const double _baseEnd = 0.6;

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
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    final elementCount = widget.data.length + 2;
    final maxStep = (1.0 - _baseEnd) / (elementCount - 1);
    final step = maxStep * 0.9;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: widget.size.getPadding(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isDark, textColor, 0, step),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    _buildAverageSection(isDark, 1, step),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    _buildChart(gridColor, textColor, step),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: widget.size.getTitleFontSize() * 0.8,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: widget.size.getItemSpacing()),
                Text(
                  widget.dateRange,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (widget.size is! SmallSize)
              Container(
                width:
                    widget.size.getIconSize() * widget.size.iconContainerScale,
                height:
                    widget.size.getIconSize() * widget.size.iconContainerScale,
                decoration: BoxDecoration(
                  color: widget.iconColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size.getIconSize(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageSection(bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.averageValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: widget.size.getLargeFontSize(),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -2,
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing()),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: widget.size.getTitleFontSize() - 4,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.size.getItemSpacing()),
            Text(
              'Daily average',
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize() + 2,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Color gridColor, Color textColor, double step) {
    // 根据尺寸动态计算图表高度
    final chartHeight =
        widget.size is SmallSize
            ? 120.0
            : widget.size is MediumSize
            ? 160.0
            : 192.0;
    // 根据尺寸动态计算 Y 轴宽度
    final yAxisWidth = widget.size.getLegendFontSize() * 2.5;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            children: [
              _buildYAxis(textColor, gridColor, step, yAxisWidth),
              SizedBox(width: widget.size.getItemSpacing()),
              Expanded(child: _buildBars(gridColor, step, chartHeight)),
            ],
          ),
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        _buildXLabels(textColor, step),
      ],
    );
  }

  Widget _buildYAxis(
    Color textColor,
    Color gridColor,
    double step,
    double yAxisWidth,
  ) {
    return SizedBox(
      width: yAxisWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          final value = (widget.maxValue / 5) * (5 - index);
          final itemAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(2 * step, 1.0, curve: Curves.easeOutCubic),
          );
          return Opacity(
            opacity: itemAnimation.value,
            child: Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: widget.size.getLegendFontSize(),
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBars(Color gridColor, double step, double chartHeight) {
    return Stack(
      children: [_buildGridLines(gridColor), _buildDataBars(step, chartHeight)],
    );
  }

  Widget _buildGridLines(Color gridColor) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: index < 5 ? gridColor.withOpacity(0.5) : gridColor,
                    width: index < 5 ? 1 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              margin: EdgeInsets.only(bottom: index < 5 ? 0 : 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataBars(double step, double chartHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.data.length, (index) {
        final barAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (2 + index) * step,
            _baseEnd + (2 + index) * step,
            curve: Curves.easeOutCubic,
          ),
        );

        final height = (widget.data[index] / widget.maxValue);

        return Expanded(
          child: Container(
            height: chartHeight,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: widget.size.getBarWidth(),
              height: chartHeight * height * barAnimation.value,
              decoration: BoxDecoration(
                color: widget.iconColor,
                borderRadius: BorderRadius.circular(
                  widget.size is SmallSize ? 2 : 4,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildXLabels(Color textColor, double step) {
    final labelsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    return Opacity(
      opacity: labelsAnimation.value,
      child: Padding(
        padding: EdgeInsets.only(left: widget.size.getPadding().left + 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            widget.labels.length,
            (index) => Expanded(
              child: Center(
                child: Text(
                  widget.labels[index],
                  style: TextStyle(
                    fontSize: widget.size.getLegendFontSize(),
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
