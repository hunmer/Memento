import 'dart:math' as math;
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 环形数据段
class RingSegmentData {
  final String label;
  final double value;
  final Color color;

  const RingSegmentData({
    required this.label,
    required this.value,
    required this.color,
  });

  /// 从 JSON 创建
  factory RingSegmentData.fromJson(Map<String, dynamic> json) {
    return RingSegmentData(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
      color: Color(json['color'] as int),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color.value,
    };
  }
}

/// 堆叠环形图统计小组件
class StackedRingChartCardWidget extends StatefulWidget {
  /// 环形数据段列表
  final List<RingSegmentData> segments;

  /// 总容量
  final double total;

  /// 标题
  final String title;

  /// 已使用值
  final double usedValue;

  /// 单位（如 GB、MB 等）
  final String unit;

  /// 使用量标签（默认为 "Used storage"）
  final String? usedLabel;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const StackedRingChartCardWidget({
    super.key,
    required this.segments,
    required this.total,
    required this.title,
    required this.usedValue,
    this.unit = '',
    this.usedLabel,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例
  factory StackedRingChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final segmentsList = props['segments'] as List<dynamic>?;
    final segments = segmentsList?.map((segmentJson) {
      return RingSegmentData.fromJson(segmentJson as Map<String, dynamic>);
    }).toList() ?? [];

    return StackedRingChartCardWidget(
      segments: segments,
      total: (props['total'] as num?)?.toDouble() ?? 100.0,
      title: props['title'] as String? ?? '',
      usedValue: (props['usedValue'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      usedLabel: props['usedLabel'] as String?,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<StackedRingChartCardWidget> createState() =>
      _StackedRingChartCardWidgetState();
}

class _StackedRingChartCardWidgetState extends State<StackedRingChartCardWidget>
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
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.white : Colors.black;
    final buttonBgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    // 计算使用率百分比
    final percentage = (widget.segments.fold<double>(0, (sum, s) => sum + s.value) / widget.total * 100).round();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 250,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 环形图和图例
                  _buildChartSection(isDark, percentage),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 标题
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: widget.size.getTitleFontSize() - 8,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: widget.size.getItemSpacing()),
                  // 底部信息
                  _buildBottomSection(textColor, secondaryTextColor, iconColor, buttonBgColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建图表区域
  Widget _buildChartSection(bool isDark, int percentage) {
    return Row(
      children: [
        // 环形图
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _RingChartPainter(
              segments: widget.segments,
              total: widget.total,
              progress: _animation.value,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                '${(percentage * _animation.value).toInt()}%',
                style: TextStyle(
                  fontSize: widget.size.getLargeFontSize() - 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: widget.size.getItemSpacing()),
        // 图例
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: widget.segments.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              final itemAnimation = CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.12,
                  0.5 + index * 0.12,
                  curve: Curves.easeOutCubic,
                ),
              );
              return _LegendItem(
                label: segment.label,
                color: segment.color,
                animation: itemAnimation,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建底部区域
  Widget _buildBottomSection(
    Color textColor,
    Color secondaryTextColor,
    Color iconColor,
    Color buttonBgColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.usedLabel ?? 'Used storage',
                style: TextStyle(
                  fontSize: widget.size.getLegendFontSize(),
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              SizedBox(height: widget.size.getItemSpacing() / 1.5),
              Row(
                children: [
                  // 堆叠圆点
                  WidgetWrapper(
                    width: 16,
                    height: 16,
                    offset: -6.0,
                    children:
                        widget.segments.asMap().entries.map((entry) {
                      final segment = entry.value;
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: widget.size.getItemSpacing()),
                  // 使用量数字
                  AnimatedFlipCounter(
                    value: widget.usedValue * _animation.value,
                    fractionDigits: 0,
                    textStyle: TextStyle(
                      fontSize: widget.size.getLargeFontSize() - 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontSize: widget.size.getSubtitleFontSize(),
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 图例项
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final Animation<double> animation;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: widget.size.getSmallSpacing()),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: widget.size.getLegendFontSize() - 1,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// 堆叠圆点包装器
class WidgetWrapper extends StatelessWidget {
  final double width;
  final double height;
  final double offset;
  final List<Widget> children;

  const WidgetWrapper({
    super.key,
    required this.width,
    required this.height,
    required this.offset,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * children.length + (children.length - 1) * offset.abs(),
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Positioned(
            left: index * offset,
            child: child,
          );
        }).toList(),
      ),
    );
  }
}

/// 环形图绘制器
class _RingChartPainter extends CustomPainter {
  final List<RingSegmentData> segments;
  final double total;
  final double progress;
  final Color backgroundColor;

  _RingChartPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 计算起始角度（135度转换为弧度）
    const startAngle = 135 * math.pi / 180;
    double currentAngle = startAngle;

    // 绘制每个扇段
    for (final segment in segments) {
      final sweepAngle = (segment.value / total * 360) * math.pi / 180 * progress;
      final adjustedSweepAngle = sweepAngle > 6.28 ? 6.28 : sweepAngle;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        adjustedSweepAngle,
        false,
        paint,
      );

      currentAngle += adjustedSweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
