import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 柱状图数据模型
class BarData {
  final double value1;
  final double value2;

  const BarData({
    required this.value1,
    required this.value2,
  });

  /// 从 JSON 创建（用于公共小组件系统）
  factory BarData.fromJson(Map<String, dynamic> json) {
    return BarData(
      value1: (json['value1'] as num?)?.toDouble() ?? 0.0,
      value2: (json['value2'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON（用于公共小组件系统）
  Map<String, dynamic> toJson() {
    return {
      'value1': value1,
      'value2': value2,
    };
  }
}

/// 垂直柱状图卡片小组件
class VerticalBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String dataLabel1;
  final String dataLabel2;
  final List<BarData> bars;
  final Color? primaryColor;
  final Color? secondaryColor;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 小组件尺寸
  final HomeWidgetSize size;

  const VerticalBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dataLabel1,
    required this.dataLabel2,
    required this.bars,
    this.primaryColor,
    this.secondaryColor,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory VerticalBarChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final barsList = (props['bars'] as List<dynamic>?)
            ?.map((e) => BarData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return VerticalBarChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      dataLabel1: props['dataLabel1'] as String? ?? '',
      dataLabel2: props['dataLabel2'] as String? ?? '',
      bars: barsList,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
      secondaryColor: props['secondaryColor'] != null
          ? Color(props['secondaryColor'] as int)
          : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<VerticalBarChartCardWidget> createState() =>
      _VerticalBarChartCardWidgetState();
}

class _VerticalBarChartCardWidgetState extends State<VerticalBarChartCardWidget>
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
    final primaryColor =
        widget.primaryColor ?? const Color(0xFF0072B5);
    final secondaryColor =
        widget.secondaryColor ?? const Color(0xFF00A8CC);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.inline ? double.maxFinite : 350,
        height: widget.inline ? double.maxFinite : 320,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: widget.size.getPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF111827),
                          fontSize: widget.size.getTitleFontSize(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: widget.size.getSmallSpacing()),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          fontSize: widget.size.getSubtitleFontSize(),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: isDark
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFF111827),
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: widget.size.getTitleSpacing()),

              // 图例
              Row(
                children: [
                  _LegendItem(
                    color: primaryColor,
                    label: widget.dataLabel1,
                    isDark: isDark,
                    size: widget.size,
                  ),
                  SizedBox(width: widget.size.getItemSpacing()),
                  _LegendItem(
                    color: secondaryColor,
                    label: widget.dataLabel2,
                    isDark: isDark,
                    size: widget.size,
                  ),
                ],
              ),
              SizedBox(height: widget.size.getItemSpacing()),

              // 柱状图
              Expanded(
                child: _BarChart(
                  bars: widget.bars,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  isDark: isDark,
                  animation: _animation,
                  size: widget.size,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图例项
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  final HomeWidgetSize size;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: size.getLegendIndicatorWidth(),
          height: size.getLegendIndicatorHeight(),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: size.getSmallSpacing()),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
            fontSize: size.getLegendFontSize(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 柱状图主体
class _BarChart extends StatelessWidget {
  final List<BarData> bars;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _BarChart({
    required this.bars,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 计算最大值用于缩放
    double maxValue = 0;
    for (var bar in bars) {
      final total = bar.value1 + bar.value2;
      if (total > maxValue) maxValue = total;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;

        return Stack(
      children: [
        // 背景网格线
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.getPadding().right),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => Container(
                  width: 1,
                  height: double.infinity,
                  color: (isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB))
                      .withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),

        // 基准线
        Positioned(
          bottom: maxHeight * 0.3,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color:
                isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),

        // 柱子
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            bars.length,
            (index) => _Bar(
              data: bars[index],
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              maxValue: maxValue,
              maxHeight: maxHeight,
              animation: animation,
              index: index,
              size: size,
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

/// 单个柱子
class _Bar extends StatelessWidget {
  final BarData data;
  final Color primaryColor;
  final Color secondaryColor;
  final double maxValue;
  final double maxHeight;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _Bar({
    required this.data,
    required this.primaryColor,
    required this.secondaryColor,
    required this.maxValue,
    required this.maxHeight,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final barAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.08,
        (index * 0.08 + 0.3).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    final height1 = data.value1 / maxValue * maxHeight;
    final height2 = data.value2 / maxValue * maxHeight;

    return AnimatedBuilder(
      animation: barAnimation,
      builder: (context, child) {
        final currentHeight1 = height1 * barAnimation.value;
        final currentHeight2 = height2 * barAnimation.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: size.getBarWidth(),
              height: currentHeight1,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ),
            SizedBox(height: size.getBarSpacing()),
            Container(
              width: size.getBarWidth(),
              height: currentHeight2,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
