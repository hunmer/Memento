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
    this.size = HomeWidgetSize.medium,
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
        width: widget.inline ? double.maxFinite : 170,
        height: widget.inline ? double.maxFinite : 170,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              _buildHeader(context),
              // 时间线区域
              _buildTimeline(context),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 位置和方向图标
        Row(
          children: [
            SizedBox(
              height: 17,
              child: Center(
                child: Text(
                  widget.data.location,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.2,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(width: widget.size.getItemSpacing() / 2),
            Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Icon(
                Icons.navigation,
                size: 14,
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.size.getItemSpacing() / 4),
        // 主标题
        SizedBox(
          height: 25,
          child: Center(
            child: Text(
              widget.data.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.0,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        SizedBox(height: widget.size.getItemSpacing() / 2),
        // 描述文本
        SizedBox(
          height: 15,
          child: Text(
            widget.data.description,
            style: TextStyle(
              fontSize: 11,
              color: subTextColor,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);
    final gridColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

    return SizedBox(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 进度条区域
          SizedBox(
            height: 32,
            child: Stack(
              children: [
                // 网格线背景
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TimelineGridPainter(color: gridColor),
                  ),
                ),
                // 当前进度指示器（橙色小点）
                Positioned(
                  left: 4,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 绿色进度条
                Positioned(
                  left: 4,
                  top: 4,
                  bottom: 4,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: (170 - 32 - 4) * widget.data.progressPercent * _animation.value,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E076),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.size.getItemSpacing() / 2),
          // 时间标签
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: SizedBox(
                    height: 12,
                    child: Center(
                      child: Text(
                        widget.data.currentTimeLabel,
                        style: TextStyle(
                          fontSize: 10,
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
                    left: 170 * 0.33 - 16,
                    child: SizedBox(
                      height: 12,
                      child: Center(
                        child: Text(
                          widget.data.timeLabels[0],
                          style: TextStyle(
                            fontSize: 10,
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
                    left: 170 * 0.66 - 16,
                    child: SizedBox(
                      height: 12,
                      child: Center(
                        child: Text(
                          widget.data.timeLabels[1],
                          style: TextStyle(
                            fontSize: 10,
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

  _TimelineGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

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
    return oldDelegate.color != color;
  }
}
