import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 分段分类数据模型
///
/// 用于表示分段统计卡片中的每个分类项，支持名称、数值和颜色配置。
/// 适用于存储分段、预算分类、时间分段等多种分段统计场景。
class SegmentedCategory {
  /// 分类名称
  final String name;

  /// 分类数值（如存储空间GB、预算金额等）
  final double value;

  /// 分类显示颜色（可选，未指定时使用默认颜色）
  final Color? color;

  const SegmentedCategory({
    required this.name,
    required this.value,
    this.color,
  });

  /// 从 JSON 创建实例
  factory SegmentedCategory.fromJson(Map<String, dynamic> json) {
    return SegmentedCategory(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      color: json['color'] != null
          ? Color(int.parse(json['color'] as String))
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'color': color?.value.toRadixString(16),
    };
  }

  /// 复制并修改部分属性
  SegmentedCategory copyWith({
    String? name,
    double? value,
    Color? color,
  }) {
    return SegmentedCategory(
      name: name ?? this.name,
      value: value ?? this.value,
      color: color ?? this.color,
    );
  }
}

/// 分段统计卡片小组件
///
/// 用于展示分段使用情况的卡片组件，支持动画效果和主题适配。
/// 适用于展示设备存储、云存储、预算分类、时间分段等多种分段统计场景。
///
/// 使用示例：
/// ```dart
/// StorageBreakdownCard(
///   title: 'Device Storage',
///   used: 345,
///   total: 512,
///   categories: [
///     SegmentedCategory(
///       name: 'Application',
///       value: 96,
///       color: Color(0xFFFF3B30),
///     ),
///     SegmentedCategory(
///       name: 'Photos',
///       value: 62,
///       color: Color(0xFF34C759),
///     ),
///     SegmentedCategory(
///       name: 'iCloud Drive',
///       value: 41,
///       color: Color(0xFFFF9500),
///     ),
///     SegmentedCategory(name: 'System Data', value: 146, color: null),
///   ],
/// )
/// ```
class StorageBreakdownCard extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 已使用存储空间（GB）
  final double used;

  /// 总存储空间（GB）
  final double total;

  /// 分类列表
  final List<SegmentedCategory> categories;

  const StorageBreakdownCard({
    super.key,
    required this.title,
    required this.used,
    required this.total,
    required this.categories,
  });

  @override
  State<StorageBreakdownCard> createState() => _StorageBreakdownCardState();
}

class _StorageBreakdownCardState extends State<StorageBreakdownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  double get usagePercentage => widget.used / widget.total;

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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 340,
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和容量显示
                  _HeaderSection(
                    title: widget.title,
                    used: widget.used,
                    total: widget.total,
                    animation: _animation,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // 分段进度条
                  _StorageBar(
                    categories: widget.categories,
                    total: widget.total,
                    isDark: isDark,
                    animation: _animation,
                  ),
                  const SizedBox(height: 28),

                  // 图例
                  _LegendSection(
                    categories: widget.categories,
                    animation: _animation,
                    isDark: isDark,
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

/// 头部信息区域
class _HeaderSection extends StatelessWidget {
  final String title;
  final double used;
  final double total;
  final Animation<double> animation;
  final bool isDark;

  const _HeaderSection({
    required this.title,
    required this.used,
    required this.total,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedFlipCounter(
                      value: used * itemAnimation.value,
                      fractionDigits: 0,
                      textStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                        letterSpacing: -1,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'GB',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 6),
                      child: Text(
                        '/ $total GB',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 存储分段进度条
class _StorageBar extends StatelessWidget {
  final List<SegmentedCategory> categories;
  final double total;
  final bool isDark;
  final Animation<double> animation;

  const _StorageBar({
    required this.categories,
    required this.total,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              const gap = 4.0; // 段之间的间隙

              // 计算每段的累积位置
              double currentLeft = 0;
              final segments = <Widget>[];

              for (int index = 0; index < categories.length; index++) {
                final category = categories[index];
                final width = (category.value / total) * barWidth;

                // 计算每个段的延迟动画
                const step = 0.08;
                final start = (index * step).clamp(0.0, 0.5);
                final end = (0.4 + index * step).clamp(0.0, 1.0);
                final segmentAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                );

                final animatedWidth =
                    (width - (index < categories.length - 1 ? gap : 0)) *
                        segmentAnimation.value;

                segments.add(
                  Positioned(
                    left: currentLeft,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: animatedWidth,
                      margin: EdgeInsets.only(
                        right: index < categories.length - 1 ? gap / 2 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: category.color ??
                            (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );

                currentLeft += width;
              }

              return SizedBox(
                height: 48,
                width: barWidth,
                child: Stack(children: segments),
              );
            },
          ),
        );
      },
    );
  }
}

/// 图例区域
class _LegendSection extends StatelessWidget {
  final List<SegmentedCategory> categories;
  final Animation<double> animation;
  final bool isDark;

  const _LegendSection({
    required this.categories,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 3.5,
            children: List.generate(categories.length, (index) {
              final category = categories[index];
              const step = 0.1;
              final start = (index * step).clamp(0.0, 0.4);
              final end = (0.6 + index * step).clamp(0.0, 1.0);
              final legendAnimation = CurvedAnimation(
                parent: animation,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return _LegendItem(
                name: category.name,
                color: category.color ??
                    (isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                animation: legendAnimation,
              );
            }),
          ),
        );
      },
    );
  }
}

/// 单个图例项
class _LegendItem extends StatelessWidget {
  final String name;
  final Color color;
  final Animation<double> animation;

  const _LegendItem({
    required this.name,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - animation.value)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 2),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
