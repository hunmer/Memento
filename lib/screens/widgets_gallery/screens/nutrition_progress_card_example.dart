import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 营养进度卡片示例
class NutritionProgressCardExample extends StatelessWidget {
  const NutritionProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('营养进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: NutritionProgressCardWidget(
            calories: NutritionData(current: 470, total: 1830, unit: 'Cal'),
            nutrients: [
              NutrientData(
                icon: '🍔',
                name: 'Protein',
                current: 66,
                total: 94,
                color: Color(0xFF34D399), // emerald-400
              ),
              NutrientData(
                icon: '🍉',
                name: 'Carbs',
                current: 35,
                total: 64,
                color: Color(0xFFFED7AA), // orange-300
              ),
              NutrientData(
                icon: '🥛',
                name: 'Fats',
                current: 21,
                total: 32,
                color: Color(0xFF3B82F6), // blue-500
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
}

/// 营养进度卡片小组件
class NutritionProgressCardWidget extends StatefulWidget {
  /// 卡路里数据
  final NutritionData calories;

  /// 营养素列表
  final List<NutrientData> nutrients;

  const NutritionProgressCardWidget({
    super.key,
    required this.calories,
    required this.nutrients,
  });

  @override
  State<NutritionProgressCardWidget> createState() =>
      _NutritionProgressCardWidgetState();
}

class _NutritionProgressCardWidgetState
    extends State<NutritionProgressCardWidget>
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
                  // 左侧：卡路里区域
                  Expanded(
                    child: _CaloriesSection(
                      data: widget.calories,
                      animation: _animation,
                    ),
                  ),
                  // 中间分隔线
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFE5E7EB),
                  ),
                  // 右侧：营养素列表
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

/// 卡路里区域组件
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
        // 标题
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
        // 数值
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
        // 进度条背景
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
        // 剩余卡路里
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

/// 营养素列表区域组件
class _NutrientsSection extends StatelessWidget {
  final List<NutrientData> nutrients;
  final Animation<double> animation;

  const _NutrientsSection({required this.nutrients, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

/// 单个营养素项组件
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

    // 计算延迟动画
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
        // 标题行
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
                    color:
                        isDark ? Colors.grey.shade100 : const Color(0xFF111827),
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
        // 进度条
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
