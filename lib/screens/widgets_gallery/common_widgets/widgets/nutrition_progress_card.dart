import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 卡路里数据模型
class NutritionData {
  final double current;
  final double total;
  final String unit;

  const NutritionData({
    required this.current,
    required this.total,
    required this.unit,
  });

  /// 从 JSON 创建
  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
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

/// 营养素数据模型
class NutrientData {
  final String icon;
  final String name;
  final double current;
  final double total;
  final Color color;

  const NutrientData({
    required this.icon,
    required this.name,
    required this.current,
    required this.total,
    required this.color,
  });

  /// 从 JSON 创建
  factory NutrientData.fromJson(Map<String, dynamic> json) {
    return NutrientData(
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

/// 营养进度卡片小组件
class NutritionProgressCardWidget extends StatefulWidget {
  final NutritionData calories;
  final List<NutrientData> nutrients;

  const NutritionProgressCardWidget({
    super.key,
    required this.calories,
    required this.nutrients,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory NutritionProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final caloriesData = props['calories'] != null
        ? NutritionData.fromJson(props['calories'] as Map<String, dynamic>)
        : const NutritionData(current: 0, total: 100, unit: '');

    final nutrientsList = (props['nutrients'] as List<dynamic>?)
            ?.map((e) => NutrientData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return NutritionProgressCardWidget(
      calories: caloriesData,
      nutrients: nutrientsList,
    );
  }

  @override
  State<NutritionProgressCardWidget> createState() =>
      _NutritionProgressCardWidgetState();
}

class _NutritionProgressCardWidgetState extends State<NutritionProgressCardWidget>
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
              width: 360,
              height: 180,
              padding: const EdgeInsets.all(20),
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
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _NutrientsSection(
                      nutrients: widget.nutrients,
                      animation: _animation,
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
  final NutritionData data;
  final Animation<double> animation;

  const _CaloriesSection({required this.data, required this.animation});

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
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
  final List<NutrientData> nutrients;
  final Animation<double> animation;

  const _NutrientsSection({required this.nutrients, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < nutrients.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _NutrientItem(data: nutrients[i], animation: animation, index: i),
        ],
      ],
    );
  }
}

class _NutrientItem extends StatelessWidget {
  final NutrientData data;
  final Animation<double> animation;
  final int index;

  const _NutrientItem({
    required this.data,
    required this.animation,
    required this.index,
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
        const SizedBox(height: 4),
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
