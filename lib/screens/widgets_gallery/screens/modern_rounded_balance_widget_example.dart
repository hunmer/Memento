import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 余额卡片示例
class ModernRoundedBalanceWidgetExample extends StatelessWidget {
  const ModernRoundedBalanceWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('余额卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        child: const Center(
          child: ModernRoundedBalanceWidget(
            title: 'Card Balance',
            balance: 1682.55,
            available: 8317.45,
            weeklyData: [0.45, 0.65, 0.35, 0.75, 0.70, 0.90, 0.30],
          ),
        ),
      ),
    );
  }
}

/// 余额卡片小组件
class ModernRoundedBalanceWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 当前余额
  final double balance;

  /// 可用额度
  final double available;

  /// 每周数据 (7天，0.0-1.0)
  final List<double> weeklyData;

  const ModernRoundedBalanceWidget({
    super.key,
    required this.title,
    required this.balance,
    required this.available,
    required this.weeklyData,
  });

  @override
  State<ModernRoundedBalanceWidget> createState() =>
      _ModernRoundedBalanceWidgetState();
}

class _ModernRoundedBalanceWidgetState extends State<ModernRoundedBalanceWidget>
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
    final backgroundColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final secondaryTextColor =
        isDark ? const Color(0xFFAEAEB2) : const Color(0xFF8E8E93);
    final barBgColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEFEFF4);

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 340,
              height: 250,

              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和余额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 44,
                        child: AnimatedFlipCounter(
                          value: widget.balance * _animation.value,
                          prefix: '\$',
                          fractionDigits: 2,
                          thousandSeparator: ',',
                          textStyle: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: Text(
                          '\$${widget.available.toStringAsFixed(2)} Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 每周柱状图
                  SizedBox(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final value = widget.weeklyData[index];
                        final itemAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index * 0.06,
                            0.58 + index * 0.06,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                        return _WeeklyBar(
                          label: weekDays[index],
                          value: value * itemAnimation.value,
                          backgroundColor: barBgColor,
                        );
                      }),
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

/// 每周柱状条
class _WeeklyBar extends StatelessWidget {
  final String label;
  final double value;
  final Color backgroundColor;

  const _WeeklyBar({
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  // 渐变色配置
  List<Color> get _gradients {
    // 根据数值大小生成不同的渐变
    if (value > 0.8) {
      return [
        const Color(0xFFFB923C),
        const Color(0xFF3B82F6),
      ]; // orange -> blue
    } else if (value > 0.6) {
      return [
        const Color(0xFFEF4444),
        const Color(0xFF8B5CF6),
      ]; // red -> purple
    } else if (value > 0.4) {
      return [
        const Color(0xFFFACC15),
        const Color(0xFF3B82F6),
      ]; // yellow -> blue
    } else {
      return [
        const Color(0xFFEF4444),
        const Color(0xFFA78BFA),
      ]; // red -> purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 18,
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 18,
              height: 56 * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: _gradients,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(9),
                  bottomRight: Radius.circular(9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 18,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  backgroundColor == const Color(0xFF3A3A3C)
                      ? const Color(0xFFAEAEB2)
                      : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }
}
