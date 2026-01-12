import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 排名条形图卡片示例
class RankedBarChartCardExample extends StatelessWidget {
  const RankedBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('排名条形图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF1F6),
        child: const Center(
          child: RankedBarChartCardWidget(
            title: 'Average of the first economies',
            subtitle: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
            itemCount: '8 countries',
            items: [
              RankedBarItem(label: 'Noruega', value: 1.0, color: Color(0xFF020058)),
              RankedBarItem(label: 'Australia', value: 0.9, color: Color(0xFF053876)),
              RankedBarItem(label: 'Suiza', value: 0.8, color: Color(0xFF0069A8)),
              RankedBarItem(label: 'Países Bajos', value: 0.72, color: Color(0xFF008DB6)),
              RankedBarItem(label: 'Estados Unidos', value: 0.64, color: Color(0xFF00B0CE)),
              RankedBarItem(label: 'Alemania', value: 0.56, color: Color(0xFF4CCCE3)),
              RankedBarItem(label: 'Nueva Zelanda', value: 0.48, color: Color(0xFF8EE1F1)),
              RankedBarItem(label: 'Canadá', value: 0.4, color: Color(0xFFCBF1F7)),
            ],
            footer: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
          ),
        ),
      ),
    );
  }
}

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

  /// 从 JSON 创建
  factory RankedBarItem.fromJson(Map<String, dynamic> json) {
    return RankedBarItem(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color.value,
    };
  }
}

/// 排名条形图小组件
class RankedBarChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String itemCount;
  final List<RankedBarItem> items;
  final String footer;

  const RankedBarChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.items,
    required this.footer,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory RankedBarChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = (props['items'] as List<dynamic>?)
            ?.map((e) => RankedBarItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return RankedBarChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      itemCount: props['itemCount'] as String? ?? '',
      items: itemsList,
      footer: props['footer'] as String? ?? '',
    );
  }

  @override
  State<RankedBarChartCardWidget> createState() => _RankedBarChartCardWidgetState();
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
              width: 360,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'List of countries',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              widget.itemCount,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          // 计算延迟动画
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
                          );
                        }),
                        const SizedBox(height: 32),
                        Text(
                          widget.footer,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 单个排名条组件
class _RankedBarWidget extends StatelessWidget {
  final RankedBarItem item;
  final Animation<double> animation;
  final bool isLast;

  const _RankedBarWidget({
    required this.item,
    required this.animation,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = item.value >= 0.64 ? Colors.white : const Color(0xFF0F172A);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 280 * item.value * animation.value,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.color,
                  ),
                  child: ClipRect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
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
                            value: item.value * 100 * animation.value,
                            fractionDigits: 0,
                            textStyle: TextStyle(
                              fontSize: 12,
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
