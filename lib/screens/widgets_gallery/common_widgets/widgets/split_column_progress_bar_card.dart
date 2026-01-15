import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 列进度数据模型
class ColumnProgressData {
  final double current;
  final double total;
  final String unit;

  const ColumnProgressData({
    required this.current,
    required this.total,
    required this.unit,
  });

  /// 从 JSON 创建
  factory ColumnProgressData.fromJson(Map<String, dynamic> json) {
    return ColumnProgressData(
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'total': total,
      'unit': unit,
    };
  }
}

/// 进度项数据模型
class ProgressItemData {
  final String icon;
  final String name;
  final double current;
  final double total;
  final Color color;

  const ProgressItemData({
    required this.icon,
    required this.name,
    required this.current,
    required this.total,
    required this.color,
  });

  /// 从 JSON 创建
  factory ProgressItemData.fromJson(Map<String, dynamic> json) {
    return ProgressItemData(
      icon: json['icon'] as String? ?? '',
      name: json['name'] as String? ?? '',
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'name': name,
      'current': current,
      'total': total,
      'color': color.value,
    };
  }
}

/// 左右分栏进度条卡片小组件
class SplitColumnProgressBarCard extends StatefulWidget {
  final ColumnProgressData calories;
  final List<ProgressItemData> nutrients;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 组件尺寸
  final HomeWidgetSize size;

  const SplitColumnProgressBarCard({
    super.key,
    required this.calories,
    required this.nutrients,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory SplitColumnProgressBarCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final caloriesData = props['calories'] != null
        ? ColumnProgressData.fromJson(props['calories'] as Map<String, dynamic>)
        : const ColumnProgressData(current: 0, total: 100, unit: '');

    final nutrientsList = (props['nutrients'] as List<dynamic>?)
            ?.map((e) => ProgressItemData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return SplitColumnProgressBarCard(
      calories: caloriesData,
      nutrients: nutrientsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<SplitColumnProgressBarCard> createState() =>
      _SplitColumnProgressBarCardState();
}

class _SplitColumnProgressBarCardState extends State<SplitColumnProgressBarCard>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              height: widget.inline ? double.maxFinite : 180,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CaloriesSection(
                      data: widget.calories,
                      animation: _animation,
                      size: widget.size,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(
                      horizontal: widget.size.getPadding().horizontal / 2,
                    ),
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _NutrientsSection(
                      nutrients: widget.nutrients,
                      animation: _animation,
                      size: widget.size,
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

class _CaloriesSection extends StatelessWidget {
  final ColumnProgressData data;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _CaloriesSection({
    required this.data,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              'Calories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        SizedBox(height: size.getItemSpacing()),
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 36,
                child: AnimatedFlipCounter(
                  value: data.current * animation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 18,
                child: Text(
                  data.unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size.getItemSpacing()),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (data.current / data.total) * animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: size.getItemSpacing()),
        SizedBox(
          height: 16,
          child: Text(
            '${(data.total - data.current).toInt()} ${data.unit} remaining',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _NutrientsSection extends StatelessWidget {
  final List<ProgressItemData> nutrients;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _NutrientsSection({
    required this.nutrients,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < nutrients.length; i++) ...[
          if (i > 0) SizedBox(height: size.getItemSpacing()),
          _NutrientItem(data: nutrients[i], animation: animation, index: i, size: size),
        ],
      ],
    );
  }
}

class _NutrientItem extends StatelessWidget {
  final ProgressItemData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _NutrientItem({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = 0.08;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * step,
        0.6 + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    final progress = data.current / data.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(data.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade100 : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
              child: AnimatedFlipCounter(
                value: data.current * itemAnimation.value,
                fractionDigits: data.current % 1 != 0 ? 1 : 0,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: data.color,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: size.getItemSpacing() / 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress * itemAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
