import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/timeline_status_card_data.dart';

/// 时间线状态卡片小组件
/// 用于显示时间线进度和状态信息，支持动画效果
class TimelineStatusCardWidget extends StatefulWidget {
  /// 卡片数据
  final TimelineStatusCardData data;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const TimelineStatusCardWidget({
    super.key,
    required this.data,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory TimelineStatusCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return TimelineStatusCardWidget(
      data: TimelineStatusCardData.fromJson(props),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<TimelineStatusCardWidget> createState() => _TimelineStatusCardWidgetState();
}

class _TimelineStatusCardWidgetState extends State<TimelineStatusCardWidget>
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
    final containerWidth = widget.inline ? double.maxFinite : widget.size.getWidthForChart() * 0.7;
    final containerHeight = widget.inline ? double.maxFinite : containerWidth;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(widget.size.getThumbnailImageSize() * 0.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: widget.size.getPadding(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题区域
              Expanded(
                child: _buildHeader(context),
              ),
              // 时间线区域
              _buildTimeline(context, containerWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 位置和方向图标
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: widget.size.getSubtitleFontSize(),
              child: Center(
                child: Text(
                  widget.data.location,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize() * 0.9,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.2,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(width: widget.size.getSmallSpacing()),
            Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Icon(
                Icons.navigation,
                size: widget.size.getSubtitleFontSize(),
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.size.getSmallSpacing()),
        // 主标题和副标题（垂直居中对齐）
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 主标题
              Text(
                widget.data.title,
                style: TextStyle(
                  fontSize: widget.size.getTitleFontSize(),
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: widget.size.getSmallSpacing()),
              // 描述文本
              Text(
                widget.data.description,
                style: TextStyle(
                  fontSize: widget.size.getSubtitleFontSize() * 0.75,
                  color: subTextColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, double containerWidth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);
    final gridColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final barHeight = widget.size.getLegendIndicatorHeight() * 2.5;
    final barPadding = widget.size.getSmallSpacing();
    final indicatorWidth = widget.size.getBarWidth();
    final labelFontSize = widget.size.getSubtitleFontSize() * 0.7;
    final gridStrokeWidth = widget.size.getStrokeWidth() * widget.size.progressStrokeScale;

    return SizedBox(
      height: barHeight + labelFontSize + widget.size.getSmallSpacing(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 进度条区域
          SizedBox(
            height: barHeight,
            child: Stack(
              children: [
                // 网格线背景
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TimelineGridPainter(
                      color: gridColor,
                      strokeWidth: gridStrokeWidth,
                    ),
                  ),
                ),
                // 当前进度指示器（橙色小点）
                Positioned(
                  left: barPadding,
                  top: barPadding,
                  bottom: barPadding,
                  child: Container(
                    width: indicatorWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A),
                      borderRadius: BorderRadius.circular(indicatorWidth / 2),
                    ),
                  ),
                ),
                // 绿色进度条
                Positioned(
                  left: barPadding,
                  top: barPadding,
                  bottom: barPadding,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: (containerWidth - barPadding * 2) * widget.data.progressPercent * _animation.value,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E076),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(widget.size.getBarWidth() / 2),
                            bottomRight: Radius.circular(widget.size.getBarWidth() / 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.size.getSmallSpacing()),
          // 时间标签
          SizedBox(
            height: labelFontSize,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: SizedBox(
                    height: labelFontSize,
                    child: Center(
                      child: Text(
                        widget.data.currentTimeLabel,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.data.timeLabels.isNotEmpty)
                  Positioned(
                    left: containerWidth * 0.33 - widget.size.getSubtitleFontSize() * 1.2,
                    child: SizedBox(
                      height: labelFontSize,
                      child: Center(
                        child: Text(
                          widget.data.timeLabels[0],
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w500,
                            color: subTextColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.data.timeLabels.length > 1)
                  Positioned(
                    left: containerWidth * 0.66 - widget.size.getSubtitleFontSize() * 1.2,
                    child: SizedBox(
                      height: labelFontSize,
                      child: Center(
                        child: Text(
                          widget.data.timeLabels[1],
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w500,
                            color: subTextColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 时间线网格绘制器
class _TimelineGridPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _TimelineGridPainter({
    required this.color,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    final width = size.width;
    final sectionWidth = width / 3;

    // 绘制两条垂直网格线
    for (int i = 1; i <= 2; i++) {
      final x = sectionWidth * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
