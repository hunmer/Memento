import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 分段进度条统计卡片示例
class SegmentedProgressCardExample extends StatelessWidget {
  const SegmentedProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分段进度条统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SegmentedProgressCardWidget(
            title: 'Today Spending',
            segments: [
              SegmentData(label: 'Groceries', value: 45, color: Color(0xFFE14462)),
              SegmentData(label: 'Clothes', value: 12, color: Color(0xFF7B57E0)),
              SegmentData(label: 'Leisure', value: 8, color: Color(0xFF5BAE28)),
              SegmentData(label: 'Car', value: 15, color: Color(0xFF4A4A4C)),
            ],
            available: 5089.49,
            percentage: 46,
            currency: 'AED',
          ),
        ),
      ),
    );
  }
}

/// 分段数据模型
class SegmentData {
  final String label;
  final double value;
  final Color color;

  const SegmentData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// 分段进度条统计小组件
class SegmentedProgressCardWidget extends StatefulWidget {
  final String title;
  final List<SegmentData> segments;
  final double available;
  final int percentage;
  final String currency;

  const SegmentedProgressCardWidget({
    super.key,
    required this.title,
    required this.segments,
    required this.available,
    required this.percentage,
    this.currency = 'AED',
  });

  @override
  State<SegmentedProgressCardWidget> createState() => _SegmentedProgressCardWidgetState();
}

class _SegmentedProgressCardWidgetState extends State<SegmentedProgressCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E).withOpacity(0.5) : const Color(0xFFE5E5EA);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 0.5),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 分段进度条
                  _SegmentedProgressBar(
                    segments: widget.segments,
                    isDark: isDark,
                    animation: _animation,
                  ),

                  const SizedBox(height: 20),

                  // 图例
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: widget.segments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final segment = entry.value;
                      return _LegendItem(
                        label: segment.label,
                        color: segment.color,
                        isDark: isDark,
                        animation: _animation,
                        index: index,
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  // 底部可用金额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 金额
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${widget.currency} ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                              ),
                              AnimatedFlipCounter(
                                value: widget.available * _animation.value,
                                fractionDigits: 2,
                                textStyle: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // 百分比
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AnimatedFlipCounter(
                              value: widget.percentage.toDouble() * _animation.value,
                              fractionDigits: 0,
                              suffix: '%',
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// 分段进度条
class _SegmentedProgressBar extends StatelessWidget {
  final List<SegmentData> segments;
  final bool isDark;
  final Animation<double> animation;

  const _SegmentedProgressBar({
    required this.segments,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFF5F5F5);
    final dividerColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: _buildSegments(dividerColor),
        ),
      ),
    );
  }

  List<Widget> _buildSegments(Color dividerColor) {
    final List<Widget> widgets = [];

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final segmentAnimation = CurvedAnimation(
        parent: animation,
        curve: Interval(i * 0.1, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
      );

      // 分隔线
      if (i > 0) {
        widgets.add(
          Container(
            width: 2,
            color: dividerColor,
          ),
        );
      }

      // 进度段
      widgets.add(
        Expanded(
          flex: (segment.value * 100).toInt(),
          child: AnimatedBuilder(
            animation: segmentAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: segmentAnimation.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  color: segment.color,
                ),
              );
            },
          ),
        ),
      );
    }

    // 剩余空白区域
    final usedValue = segments.fold<double>(0, (sum, s) => sum + s.value);
    final remaining = 100 - usedValue;
    if (remaining > 0) {
      widgets.add(
        Container(
          width: 2,
          color: dividerColor,
        ),
      );
      widgets.add(
        Expanded(
          flex: remaining.toInt(),
          child: Container(
            color: isDark ? Colors.black : const Color(0xFFE5E5EA),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// 图例项
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final Animation<double> animation;
  final int index;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.isDark,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.3 + index * 0.1,
        (0.8 + index * 0.1).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
