import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 存储分段小组件示例
class StorageBreakdownWidgetExample extends StatelessWidget {
  const StorageBreakdownWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('存储分段小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: StorageBreakdownWidget(
            title: 'Device Storage',
            used: 345,
            total: 512,
            categories: [
              StorageCategory(
                name: 'Application',
                usedGB: 96,
                color: Color(0xFFFF3B30),
              ),
              StorageCategory(
                name: 'Photos',
                usedGB: 62,
                color: Color(0xFF34C759),
              ),
              StorageCategory(
                name: 'iCloud Drive',
                usedGB: 41,
                color: Color(0xFFFF9500),
              ),
              StorageCategory(name: 'System Data', usedGB: 146, color: null),
            ],
          ),
        ),
      ),
    );
  }
}

/// 存储分类数据模型
class StorageCategory {
  final String name;
  final double usedGB;
  final Color? color;

  const StorageCategory({required this.name, required this.usedGB, this.color});
}

/// 存储分段小组件
class StorageBreakdownWidget extends StatefulWidget {
  final String title;
  final double used;
  final double total;
  final List<StorageCategory> categories;

  const StorageBreakdownWidget({
    super.key,
    required this.title,
    required this.used,
    required this.total,
    required this.categories,
  });

  @override
  State<StorageBreakdownWidget> createState() => _StorageBreakdownWidgetState();
}

class _StorageBreakdownWidgetState extends State<StorageBreakdownWidget>
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
                  color:
                      isDark
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
                          color:
                              isDark
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
                          color:
                              isDark
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
  final List<StorageCategory> categories;
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
              final gap = 4.0; // 段之间的间隙

              // 计算每段的累积位置
              double currentLeft = 0;
              final segments = <Widget>[];

              for (int index = 0; index < categories.length; index++) {
                final category = categories[index];
                final width = (category.usedGB / total) * barWidth;

                // 计算每个段的延迟动画
                final step = 0.08;
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
                        color:
                            category.color ??
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
  final List<StorageCategory> categories;
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
              final step = 0.1;
              final start = (index * step).clamp(0.0, 0.4);
              final end = (0.6 + index * step).clamp(0.0, 1.0);
              final legendAnimation = CurvedAnimation(
                parent: animation,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return _LegendItem(
                name: category.name,
                color:
                    category.color ??
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
