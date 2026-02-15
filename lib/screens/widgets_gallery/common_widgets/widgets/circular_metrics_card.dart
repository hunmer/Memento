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
    final iconValue = json['icon'] as int?;
    // 处理 value 可能是 int 或 String 的情况
    final valueStr = json['value'];
    final value = valueStr is int ? '$valueStr' : (valueStr as String? ?? '');
    return MetricData(
      icon: IconData(iconValue ?? Icons.info.codePoint, fontFamily: 'MaterialIcons'),
      value: value,
      label: json['label'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      color: Color((json['color'] as int?) ?? 0xFF2196F3),
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

  /// 组件尺寸
  final HomeWidgetSize size;

  const CircularMetricsCardWidget({
    super.key,
    required this.title,
    required this.metrics,
    this.inline = false,
    this.size = const MediumSize(),
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
      size: size,
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
              constraints:
                  widget.inline ? null : widget.size.getHeightConstraints(),
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
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
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 指标列表（支持滚动）
                  Expanded(child: _buildMetricsList(context, isDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建可滚动的指标列表
  Widget _buildMetricsList(BuildContext context, bool isDark) {
    final metrics = widget.metrics;

    if (metrics.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.size.getItemSpacing()),
          child: _MetricItemWidget(
            data: metrics[index],
            animation: _animation,
            index: index,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// 单个指标项组件
class _MetricItemWidget extends StatelessWidget {
  final MetricData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _MetricItemWidget({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
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

    // 根据 size 计算各元素尺寸
    final iconSize = size.getIconSize();
    final containerSize = iconSize * size.iconContainerScale;
    final strokeWidth = size.getStrokeWidth() * size.progressStrokeScale;
    final valueFontSize = size.getLargeFontSize() * 0.35;
    final labelFontSize = size.getSubtitleFontSize();
    final itemSpacing = size.getSmallSpacing() * 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 环形进度条
        SizedBox(
          width: containerSize,
          height: containerSize,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: data.progress * itemAnimation.value,
              color: data.color,
              backgroundColor: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFF3F4F6),
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Icon(data.icon, size: iconSize * 0.8, color: data.color),
            ),
          ),
        ),
        SizedBox(width: itemSpacing),
        // 数值和标签
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: valueFontSize * 1.2,
              child: Text(
                data.value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(height: size.getSmallSpacing()),
            SizedBox(
              height: labelFontSize * 1.2,
              child: Text(
                data.label,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize: labelFontSize,
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
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // 背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆弧
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
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
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
