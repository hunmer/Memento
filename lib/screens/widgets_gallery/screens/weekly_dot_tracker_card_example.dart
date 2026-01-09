import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 周点阵追踪卡片示例
class WeeklyDotTrackerCardExample extends StatelessWidget {
  const WeeklyDotTrackerCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('周点阵追踪卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        child: const Center(
          child: WeeklyDotTrackerCardWidget(
            title: 'Nutrition',
            icon: Icons.eco,
            currentValue: 998,
            unit: 'kcal',
            status: 'On Track',
            weekDays: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            dotStates: [
              [false, true, true],    // M
              [false, false, true],   // T
              [false, true, true],    // W
              [true, true, false],    // T
              [false, false, false],  // F
              [true, false, false],   // S
              [true, true, false],    // S
            ],
          ),
        ),
      ),
    );
  }
}

/// 周点阵追踪小组件
class WeeklyDotTrackerCardWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final int currentValue;
  final String unit;
  final String status;
  final List<String> weekDays;
  final List<List<bool>> dotStates;

  const WeeklyDotTrackerCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.weekDays,
    required this.dotStates,
  });

  @override
  State<WeeklyDotTrackerCardWidget> createState() => _WeeklyDotTrackerCardWidgetState();
}

class _WeeklyDotTrackerCardWidgetState extends State<WeeklyDotTrackerCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final primaryColor = Theme.of(context).colorScheme.secondary;
    final primaryLight = isDark
        ? primaryColor.withOpacity(0.3)
        : primaryColor.withOpacity(0.4);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 380,
              height: 200,

              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, isDark, primaryColor, textColor, mutedColor),
                  const SizedBox(height: 32),

                  // 主要内容
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 数值显示
                      _buildValueDisplay(textColor, mutedColor),
                      // 点阵进度
                      _buildDotsGrid(primaryColor, primaryLight),
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

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor, Color textColor, Color mutedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Transform.rotate(
              angle: -0.78, // -45 degrees
              child: Icon(
                widget.icon,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(
            Icons.chevron_right,
            color: mutedColor,
            size: 20,
          ),
          label: Text(
            'Today',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedFlipCounter(
                value: widget.currentValue * _animation.value,
                textStyle: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.status,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDotsGrid(Color primaryColor, Color primaryLight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyDotColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Row(
      children: List.generate(
        7,
        (index) {
          // 计算安全的 step 值，确保最大 end 值不超过 1.0
          // 公式: step <= (1.0 - baseEnd) / (elementCount - 1)
          // step <= (1.0 - 0.6) / 6 = 0.066
          final step = 0.06;
          final itemAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * step,
              0.6 + index * step,
              curve: Curves.easeOutCubic,
            ),
          );

          return _DayDotColumn(
            day: widget.weekDays[index],
            dotStates: widget.dotStates[index],
            primaryColor: primaryColor,
            primaryLight: primaryLight,
            emptyDotColor: emptyDotColor,
            animation: itemAnimation,
          );
        },
      ).toList(),
    );
  }
}

/// 每日点阵列组件
class _DayDotColumn extends StatelessWidget {
  final String day;
  final List<bool> dotStates;
  final Color primaryColor;
  final Color primaryLight;
  final Color emptyDotColor;
  final Animation<double> animation;

  const _DayDotColumn({
    required this.day,
    required this.dotStates,
    required this.primaryColor,
    required this.primaryLight,
    required this.emptyDotColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) {
                final isEnabled = index < dotStates.length && dotStates[index];
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isEnabled ? animation.value : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? (index == 0 && dotStates.every((s) => !s)
                                  ? primaryLight
                                  : primaryColor)
                              : emptyDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
              ),
          ),
        ],
      ),
    );
  }
}
