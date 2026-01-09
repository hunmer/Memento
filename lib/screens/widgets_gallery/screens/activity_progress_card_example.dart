import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 活动进度卡片示例
class ActivityProgressCardExample extends StatelessWidget {
  const ActivityProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('活动进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: ActivityProgressCardWidget(
            title: 'Mileage',
            subtitle: 'January 2025',
            value: 153.20,
            unit: 'km',
            activities: 15,
            totalProgress: 20,
            completedProgress: 17,
          ),
        ),
      ),
    );
  }
}

/// 活动进度小组件
class ActivityProgressCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final double value;
  final String unit;
  final int activities;
  final int totalProgress;
  final int completedProgress;

  const ActivityProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.activities,
    required this.totalProgress,
    required this.completedProgress,
  });

  @override
  State<ActivityProgressCardWidget> createState() => _ActivityProgressCardWidgetState();
}

class _ActivityProgressCardWidgetState extends State<ActivityProgressCardWidget>
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
              width: 360,
              height: 170,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // 右上角装饰点阵
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(isDark ? 0.3 : 0.2),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(26),
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return RadialGradient(
                            center: Alignment.topRight,
                            radius: 1.0,
                            colors: [
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.8],
                            tileMode: TileMode.mirror,
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: CustomPaint(
                          painter: _DotPatternPainter(
                            color: primaryColor,
                            dotSize: 1,
                            spacing: 6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 内容
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题和图标
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.directions_run,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // 数值和活动数
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AnimatedFlipCounter(
                                  value: widget.value * _animation.value,
                                  fractionDigits: 2,
                                  textStyle: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.unit,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${widget.activities} activities',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 进度点
                        _ProgressDots(
                          total: widget.totalProgress,
                          completed: widget.completedProgress,
                          color: primaryColor,
                          animation: _animation,
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

/// 进度点组件
class _ProgressDots extends StatelessWidget {
  final int total;
  final int completed;
  final Color color;
  final Animation<double> animation;

  const _ProgressDots({
    required this.total,
    required this.completed,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final isCompleted = index < completed;
        final dotAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * 0.03,
            0.4 + index * 0.03,
            curve: Curves.easeOutCubic,
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: AnimatedBuilder(
            animation: dotAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: dotAnimation.value,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * dotAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? color
                          : color.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// 点阵装饰画笔
class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;

  _DotPatternPainter({
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) => false;
}
