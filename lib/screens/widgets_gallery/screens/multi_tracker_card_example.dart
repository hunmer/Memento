import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 多追踪器卡片示例
class MultiTrackerCardExample extends StatelessWidget {
  const MultiTrackerCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('多追踪器卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MultiTrackerCardWidget(
            trackers: [
              TrackerData(
                emoji: '🐱',
                progress: 88.0,
                progressColor: Color(0xFFFFD60A),
                title: "Peach's Life",
                subtitle: 'July 21, 2019 • 321 days',
                value: 0.88,
                unit: 'years old',
              ),
              TrackerData(
                emoji: '📅',
                progress: 71.23,
                progressColor: Color(0xFFFFD60A),
                title: '2020 Progress',
                subtitle: '157d/366d • Passed',
                value: 71.23,
                unit: '%',
              ),
              TrackerData(
                emoji: '🏡',
                progress: 65.5,
                progressColor: Color(0xFF34C759),
                title: 'Work from home',
                subtitle: 'Jan 22, 2020 • Passed',
                value: 239,
                unit: 'days',
              ),
            ],
            backgroundColor: Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }
}

/// 追踪器数据模型
class TrackerData {
  /// Emoji图标
  final String emoji;

  /// 进度值 0-100
  final double progress;

  /// 进度条颜色
  final Color progressColor;

  /// 标题
  final String title;

  /// 副标题
  final String subtitle;

  /// 数值
  final double value;

  /// 单位
  final String unit;

  const TrackerData({
    required this.emoji,
    required this.progress,
    required this.progressColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
  });
}

/// 多追踪器卡片小组件
class MultiTrackerCardWidget extends StatefulWidget {
  /// 追踪器数据列表
  final List<TrackerData> trackers;

  /// 卡片背景色
  final Color backgroundColor;

  const MultiTrackerCardWidget({
    super.key,
    required this.trackers,
    required this.backgroundColor,
  });

  @override
  State<MultiTrackerCardWidget> createState() => _MultiTrackerCardWidgetState();
}

class _MultiTrackerCardWidgetState extends State<MultiTrackerCardWidget>
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
    return Container(
      width: 380,
      constraints: const BoxConstraints(minWidth: 280),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.backgroundColor.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 渐变叠加层
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            // 追踪器列表
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.trackers.length; i++) ...[
                    if (i > 0) const SizedBox(height: 24),
                    _TrackerItem(
                      data: widget.trackers[i],
                      animation: _animation,
                      index: i,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个追踪器项
class _TrackerItem extends StatelessWidget {
  final TrackerData data;
  final Animation<double> animation;
  final int index;

  const _TrackerItem({
    required this.data,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 为每个项目添加延迟动画
        final itemAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * 0.15,
            0.6 + index * 0.15,
            curve: Curves.easeOutCubic,
          ),
        );

        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - itemAnimation.value)),
            child: Row(
              children: [
                // 带进度条的图标
                _IconWithProgress(
                  emoji: data.emoji,
                  progress: data.progress,
                  progressColor: data.progressColor,
                  animation: itemAnimation,
                ),
                const SizedBox(width: 16),
                // 标题和副标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // 数值和单位
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedFlipCounter(
                      value: data.value * itemAnimation.value,
                      fractionDigits: data.value % 1 != 0 ? 2 : 0,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.unit,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

/// 带进度条的图标
class _IconWithProgress extends StatelessWidget {
  final String emoji;
  final double progress;
  final Color progressColor;
  final Animation<double> animation;

  const _IconWithProgress({
    required this.emoji,
    required this.progress,
    required this.progressColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _CircularProgressPainter(
              progress: progress / 100 * animation.value,
              progressColor: progressColor,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          );
        },
      ),
    );
  }
}

/// 圆形进度条绘制器
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2; // 留出边距

    // 背景圆环
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.8
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆弧
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = progressColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.8
            ..strokeCap = StrokeCap.round;

      const startAngle = -90 * 3.14159 / 180; // 从顶部开始
      final sweepAngle = 2 * 3.14159 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
