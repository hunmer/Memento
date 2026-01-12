import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 指标进度数据模型
class MetricProgressData {
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

  const MetricProgressData({
    required this.emoji,
    required this.progress,
    required this.progressColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
  });

  /// 从 JSON 创建（用于公共小组件系统）
  factory MetricProgressData.fromJson(Map<String, dynamic> json) {
    return MetricProgressData(
      emoji: json['emoji'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      progressColor: Color(json['progressColor'] as int? ?? 0xFF000000),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }

  /// 转换为 JSON（用于公共小组件系统）
  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'progress': progress,
      'progressColor': progressColor.value,
      'title': title,
      'subtitle': subtitle,
      'value': value,
      'unit': unit,
    };
  }
}

/// 多指标进度卡片小组件
class MultiMetricProgressCardWidget extends StatefulWidget {
  /// 追踪器数据列表
  final List<MetricProgressData> trackers;

  /// 卡片背景色
  final Color backgroundColor;

  const MultiMetricProgressCardWidget({
    super.key,
    required this.trackers,
    required this.backgroundColor,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MultiMetricProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final trackersList = (props['trackers'] as List<dynamic>?)
            ?.map((e) => MetricProgressData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return MultiMetricProgressCardWidget(
      trackers: trackersList,
      backgroundColor: Color(props['backgroundColor'] as int? ?? 0xFF007AFF),
    );
  }

  @override
  State<MultiMetricProgressCardWidget> createState() => _MultiMetricProgressCardWidgetState();
}

class _MultiMetricProgressCardWidgetState extends State<MultiMetricProgressCardWidget>
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
                    _MetricProgressItem(
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

/// 单个指标进度项
class _MetricProgressItem extends StatelessWidget {
  final MetricProgressData data;
  final Animation<double> animation;
  final int index;

  const _MetricProgressItem({
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
