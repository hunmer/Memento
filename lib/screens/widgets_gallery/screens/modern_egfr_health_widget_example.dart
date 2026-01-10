import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 现代 eGFR 健康指标卡片示例
class ModernEgfrHealthWidgetExample extends StatelessWidget {
  const ModernEgfrHealthWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('eGFR 健康指标卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: ModernEgfrHealthWidget(
            title: 'eGFR - Low Range',
            value: 4.2,
            unit: 'mL/min',
            date: 'September 2026',
            status: 'In-Range',
          ),
        ),
      ),
    );
  }
}

/// 现代 eGFR 健康指标小组件
class ModernEgfrHealthWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 数值
  final double value;

  /// 单位
  final String unit;

  /// 日期
  final String date;

  /// 状态标签
  final String status;

  const ModernEgfrHealthWidget({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.date,
    required this.status,
  });

  @override
  State<ModernEgfrHealthWidget> createState() => _ModernEgfrHealthWidgetState();
}

class _ModernEgfrHealthWidgetState extends State<ModernEgfrHealthWidget>
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
    final primaryColor =
        isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED); // Violet
    final accentColor = const Color(0xFF84CC16); // Lime

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow:
                    isDark
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 40,
                            offset: const Offset(0, -12),
                          ),
                        ],
                border:
                    isDark
                        ? Border.all(color: Colors.white.withOpacity(0.1))
                        : null,
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.science,
                              size: 24,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF9CA3AF),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 数值和状态行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 数值
                      SizedBox(
                        height: 54,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 52,
                              child: AnimatedFlipCounter(
                                value: widget.value * _animation.value,
                                fractionDigits: 1,
                                textStyle: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 22,
                              child: Text(
                                widget.unit,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 状态指示器
                      Column(
                        children: [
                          SizedBox(
                            height: 12,
                            child: Text(
                              widget.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? const Color(0xFFD1D5DB)
                                        : const Color(0xFF1F2937),
                                letterSpacing: 0.5,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 88,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFFDE68A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              children: [
                                // 渐变背景
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors:
                                            isDark
                                                ? [
                                                  const Color(0xFF365314),
                                                  const Color(0xFF3F6212),
                                                  const Color(0xFF365314),
                                                ]
                                                : [
                                                  const Color(0xFFFDE68A),
                                                  const Color(0xFFBEF264),
                                                  const Color(0xFFFDE68A),
                                                ],
                                      ),
                                    ),
                                  ),
                                ),
                                // 指示点
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isDark
                                                  ? const Color(0xFF1C1C1E)
                                                  : Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
