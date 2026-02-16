import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 周条形数据（公共小组件版本）
class CommonWeeklyBarData {
  final String label;
  final double upperHeight;
  final double lowerHeight;

  const CommonWeeklyBarData({
    required this.label,
    required this.upperHeight,
    required this.lowerHeight,
  });

  /// 从 JSON 创建
  factory CommonWeeklyBarData.fromJson(Map<String, dynamic> json) {
    return CommonWeeklyBarData(
      label: json['label'] as String? ?? '',
      upperHeight: (json['upperHeight'] as num?)?.toDouble() ?? 0.0,
      lowerHeight: (json['lowerHeight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'upperHeight': upperHeight,
      'lowerHeight': lowerHeight,
    };
  }
}

/// 周条形图小组件（公共小组件版本）
class CommonWeeklyBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int percentage;
  final List<CommonWeeklyBarData> weeklyData;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 组件尺寸
  final HomeWidgetSize size;

  const CommonWeeklyBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.weeklyData,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory CommonWeeklyBarChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final weeklyDataList = props['weeklyData'] as List?;
    final weeklyData = weeklyDataList?.map((item) {
      return CommonWeeklyBarData.fromJson(item as Map<String, dynamic>);
    }).toList() ?? <CommonWeeklyBarData>[];

    return CommonWeeklyBarChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      percentage: props['percentage'] as int? ?? 0,
      weeklyData: weeklyData,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<CommonWeeklyBarChartCardWidget> createState() =>
      _CommonWeeklyBarChartCardWidgetState();
}

class _CommonWeeklyBarChartCardWidgetState
    extends State<CommonWeeklyBarChartCardWidget>
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
              height: widget.inline ? double.maxFinite : widget.size.getHeightConstraints().maxHeight,
              width: widget.inline ? double.maxFinite : widget.size.getHeightConstraints().maxWidth,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 条形图区域
                    Expanded(
                      child: _WeeklyBars(
                        data: widget.weeklyData,
                        animation: _animation,
                        size: widget.size,
                      ),
                    ),
                    SizedBox(height: widget.size.getItemSpacing()),
                    // 底部信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: widget.size.getLargeFontSize() * 0.8,
                          child: AnimatedFlipCounter(
                            value: widget.percentage.toDouble() *
                                _animation.value,
                            fractionDigits: 0,
                            suffix: '%',
                            textStyle: TextStyle(
                              fontSize: widget.size.getLargeFontSize() * 0.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFF111827),
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: widget.size.getPadding().right * 0.6,
                                vertical: widget.size.getSmallSpacing() * 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? primaryColor.withOpacity(0.2)
                                  : const Color(0xFFBFDBFE),
                              borderRadius: BorderRadius.circular(widget.size.getPadding().right),
                            ),
                            child: Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: widget.size.getSubtitleFontSize() * 0.8,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
  final List<CommonWeeklyBarData> data;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _WeeklyBars({
    required this.data,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final lightColor = isDark
        ? Colors.blue.shade900.withOpacity(0.3)
        : Colors.blue.shade200.withOpacity(0.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final item = data[index];
        final step = 0.08;
        final barAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * step,
            0.5 + index * step,
            curve: Curves.easeOutCubic,
          ),
        );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < data.length - 1 ? size.getItemSpacing() : 0),
            child: Column(
              children: [
                // 条形图容器
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 上层浅色条
                        AnimatedBuilder(
                          animation: barAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 100 *
                                  item.upperHeight *
                                  barAnimation.value,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: lightColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        // 下层主条
                        AnimatedBuilder(
                          animation: barAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 100 *
                                  item.lowerHeight *
                                  barAnimation.value,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF4FABFF),
                                    primaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.getSmallSpacing() * 2),
                // 标签（small size 下隐藏）
                if (size is! SmallSize)
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: size.getLegendFontSize(),
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
