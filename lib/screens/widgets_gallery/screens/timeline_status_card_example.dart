import 'package:flutter/material.dart';

/// 时间线状态卡片示例
class TimelineStatusCardExample extends StatelessWidget {
  const TimelineStatusCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('时间线状态卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TimelineStatusCardWidget(
            location: 'Tiburon',
            title: 'Cleaner',
            description: 'Electricity is cleaner until 2:00 PM.',
            progressPercent: 0.65,
            currentTimeLabel: 'Now',
            timeLabels: ['12PM', '3PM'],
          ),
        ),
      ),
    );
  }
}

/// 时间线状态卡片小组件
class TimelineStatusCardWidget extends StatefulWidget {
  final String location;
  final String title;
  final String description;
  final double progressPercent;
  final String currentTimeLabel;
  final List<String> timeLabels;

  const TimelineStatusCardWidget({
    super.key,
    required this.location,
    required this.title,
    required this.description,
    required this.progressPercent,
    required this.currentTimeLabel,
    this.timeLabels = const [],
  });

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
            child: Container(
              width: 170,
              height: 170,
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
                padding: const EdgeInsets.all(16),
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
          ),
        );
      },
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
            Text(
              widget.location,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 4),
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
        const SizedBox(height: 2),
        // 主标题
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        // 描述文本
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 11,
            color: subTextColor,
            height: 1.3,
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
                        width: (170 - 32 - 4) * widget.progressPercent * _animation.value,
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
          const SizedBox(height: 4),
          // 时间标签
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: Text(
                    widget.currentTimeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (widget.timeLabels.isNotEmpty)
                  Positioned(
                    left: 170 * 0.33 - 16,
                    child: Text(
                      widget.timeLabels[0],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                      ),
                    ),
                  ),
                if (widget.timeLabels.length > 1)
                  Positioned(
                    left: 170 * 0.66 - 16,
                    child: Text(
                      widget.timeLabels[1],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
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
