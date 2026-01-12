import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 分数卡片示例
class ScoreCardWidgetExample extends StatelessWidget {
  const ScoreCardWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分数卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: ScoreCardWidget(
            score: 912,
            grade: 'A',
            actions: [
              ActionData(label: 'Charity Pay', value: 16, isPositive: true),
              ActionData(
                label: 'Traffic Violation',
                value: 24,
                isPositive: false,
              ),
              ActionData(label: 'Blood Donation', value: 42, isPositive: true),
              ActionData(label: 'Volunteering', value: 32, isPositive: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// 行为数据模型
class ActionData {
  final String label;
  final int value;
  final bool isPositive;

  const ActionData({
    required this.label,
    required this.value,
    required this.isPositive,
  });
}

/// 分数卡片小组件
class ScoreCardWidget extends StatefulWidget {
  final int score;
  final String grade;
  final List<ActionData> actions;

  const ScoreCardWidget({
    super.key,
    required this.score,
    required this.grade,
    required this.actions,
  });

  @override
  State<ScoreCardWidget> createState() => _ScoreCardWidgetState();
}

class _ScoreCardWidgetState extends State<ScoreCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color:
                      isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFF3F3F46),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 径向渐变背景
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.2),
                          radius: 1.5,
                          colors: [
                            primaryColor.withOpacity(0.4),
                            primaryColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 0.7],
                        ),
                      ),
                    ),
                  ),
                  // 内容
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 分数显示
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 160,
                                height: 48,
                                child: AnimatedFlipCounter(
                                  value:
                                      widget.score.toDouble() *
                                      _animation.value,
                                  wholeDigits: 3,
                                  fractionDigits: 0,
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                child: Text(
                                  widget.grade,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Last Actions',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 行为列表
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: List.generate(widget.actions.length, (
                              index,
                            ) {
                              final action = widget.actions[index];
                              final itemAnimation = CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.2 + index * 0.08,
                                  0.7 + index * 0.08,
                                  curve: Curves.easeOutCubic,
                                ),
                              );

                              return _ActionItem(
                                action: action,
                                animation: itemAnimation,
                              );
                            }),
                          ),
                        ),
                      ],
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

/// 行为项组件
class _ActionItem extends StatelessWidget {
  final ActionData action;
  final Animation<double> animation;

  const _ActionItem({required this.action, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final displayValue = (action.value * animation.value).round();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                action.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Text(
                    action.isPositive ? '+' : '-',
                    style: TextStyle(
                      color:
                          action.isPositive
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 60,
                    height: 24,
                    child: AnimatedFlipCounter(
                      value: displayValue.toDouble(),
                      wholeDigits: 2,
                      fractionDigits: 0,
                      textStyle: TextStyle(
                        color:
                            action.isPositive
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
