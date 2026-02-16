import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 排名条目数据模型
class RankedBarItem {
  final String label;
  final double value;
  final Color color;

  const RankedBarItem({
    required this.label,
    required this.value,
    required this.color,
  });

  factory RankedBarItem.fromJson(Map<String, dynamic> json) {
    return RankedBarItem(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value, 'color': color.value};
  }
}

class RankedBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String itemCount;
  final List<RankedBarItem> items;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const RankedBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.items,
    this.inline = false,
    this.size = const MediumSize(),
  });

  factory RankedBarChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList =
        (props['items'] as List<dynamic>?)
            ?.map((e) => RankedBarItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return RankedBarChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      itemCount: props['itemCount'] as String? ?? '',
      items: itemsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<RankedBarChartCardWidget> createState() =>
      _RankedBarChartCardWidgetState();
}

class _RankedBarChartCardWidgetState extends State<RankedBarChartCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              constraints:
                  widget.inline ? null : const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.size.getTitleFontSize(),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      maxLines: 1,
                    ),
                    SizedBox(height: widget.size.getItemSpacing()),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize(),
                        color:
                            isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      maxLines: 1,
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'List of countries',
                          style: TextStyle(
                            fontSize: widget.size.getLegendFontSize(),
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.itemCount,
                          style: TextStyle(
                            fontSize: widget.size.getLegendFontSize(),
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.size.getItemSpacing()),
                    Expanded(
                      child: SingleChildScrollView(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxValue = widget.items.first.value;
                            final maxWidth = constraints.maxWidth;
                            return Column(
                              children: widget.items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final step = 0.05;
                                final itemAnimation = CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    index * step,
                                    0.6 + index * step,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                return _RankedBarWidget(
                                  item: item,
                                  animation: itemAnimation,
                                  isLast: index == widget.items.length - 1,
                                  size: widget.size,
                                  maxValue: maxValue,
                                  maxWidth: maxWidth,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
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

class _RankedBarWidget extends StatelessWidget {
  final RankedBarItem item;
  final Animation<double> animation;
  final bool isLast;
  final HomeWidgetSize size;
  final double maxValue;
  final double maxWidth;

  const _RankedBarWidget({
    required this.item,
    required this.animation,
    required this.isLast,
    required this.size,
    required this.maxValue,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        item.value >= 0.64 ? Colors.white : const Color(0xFF0F172A);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = item.value * animation.value;
        final width = maxValue > 0 ? (animatedValue / maxValue) * maxWidth : 0.0;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
          height: size.getRankedBarItemHeight(),
          child: Row(
            children: [
              ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: width,
                    height: size.getRankedBarItemHeight(),
                    decoration: BoxDecoration(color: item.color),
                    child: ClipRect(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.getPadding().left,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: size.getLegendFontSize(),
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedFlipCounter(
                              value: item.value * 100.0 * animation.value,
                              fractionDigits: 0,
                              textStyle: TextStyle(
                                fontSize: size.getLegendFontSize(),
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}
