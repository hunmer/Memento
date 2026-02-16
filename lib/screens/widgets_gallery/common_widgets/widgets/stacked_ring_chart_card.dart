import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart'
    show HomeWidgetSize, SmallSize, MediumSize, LargeSize, WideSize, Wide2Size;

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
    return {'label': label, 'value': value, 'color': color.value};
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

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const StackedRingChartCardWidget({
    super.key,
    required this.segments,
    required this.total,
    required this.title,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory StackedRingChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final segmentsList = props['segments'] as List<dynamic>?;
    final segments =
        segmentsList?.map((segmentJson) {
          return RingSegmentData.fromJson(segmentJson as Map<String, dynamic>);
        }).toList() ??
        [];

    return StackedRingChartCardWidget(
      segments: segments,
      total: (props['total'] as num?)?.toDouble() ?? 100.0,
      title: props['title'] as String? ?? '',
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

  /// 获取环形图大小
  double get _chartSize {
    double baseSize;
    if (widget.size is SmallSize) {
      baseSize = 80;
    } else if (widget.size is MediumSize || widget.size is WideSize) {
      baseSize = 120;
    } else if (widget.size is LargeSize || widget.size is Wide2Size) {
      baseSize = 140;
    } else {
      // Large3, Wide3
      baseSize = 240;
    }
    return baseSize * widget.size.scale;
  }

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

    // 计算使用率百分比
    final percentage =
        (widget.segments.fold<double>(0, (sum, s) => sum + s.value) /
                widget.total *
                100)
            .round();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 250,
              constraints: widget.inline ? null : widget.size.getHeightConstraints(),
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: widget.size.getTitleFontSize() - 8,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 环形图和图例
                  _buildChartSection(isDark, percentage),
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
    final chartSize = _chartSize;
    // 非 wide 卡片使用纵向布局（图例在下方），wide 卡片使用横向布局（图例在右侧）
    final isVerticalLayout =
        widget.size is SmallSize ||
        widget.size is MediumSize ||
        widget.size is LargeSize;

    if (isVerticalLayout) {
      // 纵向布局：图表在上，图例在下方
      return Column(
        children: [
          // 环形图
          Center(
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: CustomPaint(
                painter: _RingChartPainter(
                  segments: widget.segments,
                  total: widget.total,
                  progress: _animation.value,
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  strokeWidth: widget.size.getStrokeWidth(),
                ),
                child: Center(
                  child: Text(
                    '${(percentage * _animation.value).toInt()}%',
                    style: TextStyle(
                      fontSize: widget.size.getLargeFontSize() - 26,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: widget.size.getItemSpacing()),
          // 图例 - 一行显示一个分类，支持纵向滚动
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children:
                    widget.segments.asMap().entries.map((entry) {
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
                        size: widget.size,
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      );
    } else {
      // 横向布局：图表在左，图例在右
      return Row(
        children: [
          // 环形图
          SizedBox(
            width: chartSize,
            height: chartSize,
            child: CustomPaint(
              painter: _RingChartPainter(
                segments: widget.segments,
                total: widget.total,
                progress: _animation.value,
                backgroundColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                strokeWidth: widget.size.getStrokeWidth(),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children:
                    widget.segments.asMap().entries.map((entry) {
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
                        size: widget.size,
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      );
    }
  }
}

/// 图例项
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.animation,
    required this.size,
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
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: size.getLegendIndicatorWidth() * 0.8,
                    height: size.getLegendIndicatorWidth() * 0.8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: size.getSmallSpacing()),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: size.getLegendFontSize() - 1,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).brightness == Brightness.dark
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

/// 环形图绘制器
class _RingChartPainter extends CustomPainter {
  final List<RingSegmentData> segments;
  final double total;
  final double progress;
  final Color backgroundColor;
  final double strokeWidth;

  _RingChartPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth * 2;

    // 绘制背景圆环
    final backgroundPaint =
        Paint()
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
      final sweepAngle =
          (segment.value / total * 360) * math.pi / 180 * progress;
      final adjustedSweepAngle = sweepAngle > 6.28 ? 6.28 : sweepAngle;

      final paint =
          Paint()
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
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
