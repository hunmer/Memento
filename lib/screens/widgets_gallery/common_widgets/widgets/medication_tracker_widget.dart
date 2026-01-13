import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 药物追踪器小组件
class MedicationTrackerWidget extends StatefulWidget {
  /// 药物数量
  final int medicationCount;

  /// 单位标签
  final String unit;

  /// 进度值 (0.0 - 1.0)
  final double progress;

  const MedicationTrackerWidget({
    super.key,
    required this.medicationCount,
    this.unit = 'meds',
    required this.progress,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MedicationTrackerWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MedicationTrackerWidget(
      medicationCount: props['medicationCount'] as int? ?? 0,
      unit: props['unit'] as String? ?? 'meds',
      progress: (props['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  State<MedicationTrackerWidget> createState() => _MedicationTrackerWidgetState();
}

class _MedicationTrackerWidgetState extends State<MedicationTrackerWidget>
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
    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final primaryColor = const Color(0xFF84CC16); // Lime-500
    final trackColor = isDark ? const Color(0xFF3F6212) : const Color(0xFFECFCCB);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        ),
                      ),
                      Icon(
                        Icons.medication_outlined,
                        size: 20,
                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                      ),
                    ],
                  ),

                  // 数量显示
                  SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 36,
                          child: AnimatedFlipCounter(
                            value: widget.medicationCount.toDouble() * _animation.value,
                            textStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 18,
                          child: Text(
                            widget.unit,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 胶囊进度条
                  SizedBox(
                    width: double.infinity,
                    child: CustomPaint(
                      size: const Size.fromHeight(70),
                      painter: _PillProgressPainter(
                        progress: widget.progress * _animation.value,
                        progressColor: primaryColor,
                        trackColor: trackColor,
                      ),
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

/// 胶囊进度条绘制器
class _PillProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;

  _PillProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const pillWidth = 160.0;
    const pillHeight = 60.0;
    const cornerRadius = 30.0;

    final rect = Rect.fromCenter(
      center: center,
      width: pillWidth,
      height: pillHeight,
    );

    // 绘制轨道
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final trackPath = _getPillPath(rect, cornerRadius);
    canvas.drawPath(trackPath, trackPaint);

    // 绘制进度
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // 计算 path 总长度和当前进度长度
    final pathMetrics = trackPath.computeMetrics();
    if (pathMetrics.isNotEmpty) {
      final pathMetric = pathMetrics.first;
      final totalLength = pathMetric.length;
      final progressLength = totalLength * progress;

      final progressPath = pathMetric.extractPath(0, progressLength);
      canvas.drawPath(progressPath, progressPaint);
    }
  }

  Path _getPillPath(Rect rect, double radius) {
    final path = Path();
    final r = radius > rect.shortestSide / 2 ? rect.shortestSide / 2 : radius;

    path.moveTo(rect.left + r, rect.top);
    path.lineTo(rect.right - r, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(rect.right, rect.bottom - r);
    path.arcToPoint(
      Offset(rect.right - r, rect.bottom),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(rect.left + r, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(rect.left, rect.top + r);
    path.arcToPoint(
      Offset(rect.left + r, rect.top),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _PillProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
