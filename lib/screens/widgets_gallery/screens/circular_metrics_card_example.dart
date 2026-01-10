import 'package:flutter/material.dart';

/// 环形指标卡片示例
class CircularMetricsCardExample extends StatelessWidget {
  const CircularMetricsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('环形指标卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CircularMetricsCardWidget(
            title: 'Overview',
            metrics: [
              MetricData(
                icon: Icons.person,
                value: '12d 23hrs',
                label: 'To complete',
                progress: 0.75,
                color: Color(0xFF34D399), // Green
              ),
              MetricData(
                icon: Icons.pets,
                value: '24',
                label: 'Team',
                progress: 0.60,
                color: Color(0xFFFB7185), // Pink
              ),
              MetricData(
                icon: Icons.savings,
                value: '20.5k',
                label: 'Budget left',
                progress: 0.40,
                color: Color(0xFFFBBF24), // Orange
              ),
              MetricData(
                icon: Icons.inventory_2,
                value: '384',
                label: 'Assigned',
                progress: 0.80,
                color: Color(0xFF6366F1), // Blue
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
}

/// 环形指标卡片小组件
class CircularMetricsCardWidget extends StatefulWidget {
  final String title;
  final List<MetricData> metrics;

  const CircularMetricsCardWidget({
    super.key,
    required this.title,
    required this.metrics,
  });

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
    final backgroundColor = isDark ? const Color(0xFF202020) : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 380,
              height: 280,
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
                      color:
                          isDark
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
    return Column(
      children: [
        // 第一行
        Row(
          children: [
            Expanded(
              child: _MetricItemWidget(
                data: metrics[0],
                animation: _animation,
                index: 0,
              ),
            ),
            Expanded(
              child: _MetricItemWidget(
                data: metrics[1],
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
                data: metrics[2],
                animation: _animation,
                index: 2,
              ),
            ),
            Expanded(
              child: _MetricItemWidget(
                data: metrics[3],
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
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
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
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF111827),
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
                  color:
                      Theme.of(context).brightness == Brightness.dark
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
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆弧
    final progressPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 从顶部开始
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
