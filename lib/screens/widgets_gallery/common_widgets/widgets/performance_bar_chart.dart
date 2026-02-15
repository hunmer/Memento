import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 柱状图数据模型
class PerformanceBarData {
  final double value;
  final String label;

  const PerformanceBarData({
    required this.value,
    required this.label,
  });

  /// 从 JSON 创建
  factory PerformanceBarData.fromJson(Map<String, dynamic> json) {
    return PerformanceBarData(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}

/// 性能指标柱状图小组件
class PerformanceBarChartWidget extends StatefulWidget {
  final String badgeLabel;
  final double growthPercentage;
  final String timePeriod;
  final List<PerformanceBarData> barData;
  final String footerLabel;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const PerformanceBarChartWidget({
    super.key,
    required this.badgeLabel,
    required this.growthPercentage,
    required this.timePeriod,
    required this.barData,
    required this.footerLabel,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory PerformanceBarChartWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final barDataList = (props['barData'] as List<dynamic>?)
            ?.map((e) => PerformanceBarData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return PerformanceBarChartWidget(
      badgeLabel: props['badgeLabel'] as String? ?? '',
      growthPercentage: (props['growthPercentage'] as num?)?.toDouble() ?? 0.0,
      timePeriod: props['timePeriod'] as String? ?? '',
      barData: barDataList,
      footerLabel: props['footerLabel'] as String? ?? '',
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
    const primaryColor = Color(0xFF7c71f5);
    const accentLime = Color(0xFFdcfeb6);
    const accentPeach = Color(0xFFffdba5);
    final gridColor = isDark ? const Color(0xFF27272a) : const Color(0xFFe5e7eb);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              height: widget.inline ? double.maxFinite : widget.size.getHeightConstraints().maxHeight,
              padding: widget.size.getPadding(),
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
                          style: TextStyle(fontSize: widget.size.getLegendFontSize(), fontWeight: FontWeight.w700, letterSpacing: 1.5),
                        ),
                      ),
                      SizedBox(height: widget.size.getTitleSpacing()),
                      AnimatedFlipCounter(
                        value: widget.growthPercentage * _animation.value,
                        fractionDigits: 0,
                        prefix: '+',
                        suffix: '%',
                        duration: const Duration(milliseconds: 1000),
                        textStyle: TextStyle(
                          fontSize: widget.size.getLargeFontSize(),
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: widget.size.getSmallSpacing()),
                      Text(
                        widget.timePeriod,
                        style: TextStyle(fontSize: widget.size.getSubtitleFontSize(), fontWeight: FontWeight.w500, color: Colors.grey.shade500, height: 1.2),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 计算柱状图区域高度：总高度 - 上下边距 - 顶部区域 - 底部区域
                  SizedBox(
                    height: widget.size.getHeightConstraints().maxHeight -
                            widget.size.getPadding().top -
                            widget.size.getPadding().bottom -
                            widget.size.getTitleSpacing() * 2 -
                            140, // 顶部区域(约120) + 底部区域(约20)
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(4, (index) => Container(height: 1, color: gridColor)),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: widget.size.getItemSpacing() / 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(widget.barData.length, (index) {
                                final bar = widget.barData[index];
                                final barAnimation = CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(index * 0.1, 0.6 + index * 0.08, curve: Curves.easeOutCubic),
                                );
                                final barHeight = widget.size.getHeightConstraints().maxHeight -
                                                widget.size.getPadding().top -
                                                widget.size.getPadding().bottom -
                                                widget.size.getTitleSpacing() * 2 -
                                                140;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: widget.size.getItemSpacing() / 4),
                                    child: _AnimatedBar(
                                      value: bar.value,
                                      label: bar.label,
                                      primaryColor: primaryColor,
                                      accentLime: accentLime,
                                      animation: barAnimation,
                                      barHeight: barHeight,
                                      size: widget.size,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                        SizedBox(width: widget.size.getItemSpacing()),
                        Text(
                          widget.footerLabel.toUpperCase(),
                          style: TextStyle(fontSize: widget.size.getLegendFontSize(), fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.5),
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

class _AnimatedBar extends StatelessWidget {
  final double value;
  final String label;
  final Color primaryColor;
  final Color accentLime;
  final Animation<double> animation;
  final double barHeight;
  final HomeWidgetSize size;

  const _AnimatedBar({
    required this.value,
    required this.label,
    required this.primaryColor,
    required this.accentLime,
    required this.animation,
    required this.barHeight,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = value * animation.value;
        final showLabel = animation.value > 0.5;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: barHeight,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: barHeight * animatedValue / 100,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
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
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
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
                                style: TextStyle(fontSize: size.getLegendFontSize(), fontWeight: FontWeight.w700, color: Colors.white),
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
