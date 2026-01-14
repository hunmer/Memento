import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 指标数据模型
class MetricData {
  final IconData icon;
  final String value;
  final String label;
  final double progress;
  final Color color;

  const MetricData({
    required this.icon,
    required this.value,
    required this.label,
    required this.progress,
    required this.color,
  });

  /// 从 JSON 创建
  factory MetricData.fromJson(Map<String, dynamic> json) {
    return MetricData(
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      value: json['value'] as String,
      label: json['label'] as String,
      progress: (json['progress'] as num).toDouble(),
      color: Color(json['color'] as int),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'icon': icon.codePoint,
      'value': value,
      'label': label,
      'progress': progress,
      'color': color.value,
    };
  }
}

/// 环形指标卡片小组件
class CircularMetricsCardWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 指标数据列表
  final List<MetricData> metrics;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const CircularMetricsCardWidget({
    super.key,
    required this.title,
    required this.metrics,
    this.inline = false,
  });

  /// 从 props 创建实例
  factory CircularMetricsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final metricsList = props['metrics'] as List<dynamic>?;
    final metrics = metricsList?.map((item) {
      return MetricData.fromJson(item as Map<String, dynamic>);
    }).toList() ?? [];

    return CircularMetricsCardWidget(
      title: props['title'] as String? ?? 'Overview',
      metrics: metrics,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<CircularMetricsCardWidget> createState() =>
      _CircularMetricsCardWidgetState();
}

class _CircularMetricsCardWidgetState extends State<CircularMetricsCardWidget>
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
    final backgroundColor =
        isDark ? const Color(0xFF202020) : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 380,
              height: widget.inline ? double.maxFinite : 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 指标网格
                  _buildMetricsGrid(context, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(BuildContext context, bool isDark) {
    final metrics = widget.metrics;

    // 如果指标数量不足4个，使用默认值填充
    final filledMetrics = List<MetricData>.filled(
      4,
      MetricData(
        icon: Icons.help_outline,
        value: '--',
        label: 'N/A',
        progress: 0.0,
        color: Colors.grey,
      ),
    );

    for (int i = 0; i < metrics.length && i < 4; i++) {
      filledMetrics[i] = metrics[i];
    }

    return Column(
      children: [
        // 第一行
        Row(
          children: [
            Expanded(
              child: _MetricItemWidget(
                data: filledMetrics[0],
                animation: _animation,
                index: 0,
              ),
            ),
            Expanded(
              child: _MetricItemWidget(
                data: filledMetrics[1],
                animation: _animation,
                index: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // 第二行
        Row(
          children: [
            Expanded(
              child: _MetricItemWidget(
                data: filledMetrics[2],
                animation: _animation,
                index: 2,
              ),
            ),
            Expanded(
              child: _MetricItemWidget(
                data: filledMetrics[3],
                animation: _animation,
                index: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 单个指标项组件
class _MetricItemWidget extends StatelessWidget {
  final MetricData data;
  final Animation<double> animation;
  final int index;

  const _MetricItemWidget({
    required this.data,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.1,
        0.6 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 环形进度条
        SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: data.progress * itemAnimation.value,
              color: data.color,
              backgroundColor: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFF3F4F6),
            ),
            child: Center(child: Icon(data.icon, size: 20, color: data.color)),
          ),
        ),
        const SizedBox(width: 12),
        // 数值和标签
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              child: Text(
                data.value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: Text(
                data.label,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 环形进度条绘制器
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;

    // 背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆弧
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
