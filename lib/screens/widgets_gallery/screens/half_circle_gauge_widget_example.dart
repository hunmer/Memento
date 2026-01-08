import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 半圆形统计小组件示例
class HalfCircleGaugeWidgetExample extends StatelessWidget {
  const HalfCircleGaugeWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('半圆形统计小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: Center(
          child: HalfCircleGaugeWidget(
            totalBudget: 10000,
            remaining: 5089.49,
            currency: 'AED',
          ),
        ),
      ),
    );
  }
}

/// 半圆形统计小组件
class HalfCircleGaugeWidget extends StatelessWidget {
  final double totalBudget;
  final double remaining;
  final String currency;

  const HalfCircleGaugeWidget({
    super.key,
    required this.totalBudget,
    required this.remaining,
    this.currency = 'AED',
  });

  double get progress => (totalBudget - remaining) / totalBudget;
  double get percentage => progress * 100;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final gaugeBackgroundColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final primaryColor = const Color(0xFF7C5CFF);

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            'Shopping',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),

          // 中间仪表盘区域
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 半圆形仪表盘
                  SizedBox(
                    width: 192,
                    height: 96,
                    child: Stack(
                      children: [
                        // 背景圆弧
                        CustomPaint(
                          size: const Size(192, 96),
                          painter: _GaugePainter(
                            progress: progress,
                            backgroundColor: gaugeBackgroundColor,
                            progressColor: primaryColor,
                            isDark: isDark,
                          ),
                        ),
                        // 图标
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 4,
                          child: Column(
                            children: [
                              Text(
                                'REMAIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                  color:
                                      isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('🛍️', style: TextStyle(fontSize: 28)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 刻度标记
                  SizedBox(
                    width: 192,
                    height: 20,
                    child: Stack(
                      children: [
                        // 0% - 左侧对齐
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Text(
                            '0%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        // 50% - 居中对齐
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '50%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                        // 100% - 右侧对齐，增加左边距
                        Positioned(
                          right: -2,
                          bottom: 0,
                          child: Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部金额显示
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _formatAmount(remaining),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  '.${_getDecimalPart(remaining)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getDecimalPart(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return parts[1];
  }
}

/// 仪表盘绘制器
class _GaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final bool isDark;

  _GaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    const strokeWidth = 24.0;

    // 计算圆角调整角度
    final angleAdjustment = math.asin(strokeWidth / (2 * radius));

    // 背景圆弧 (180度，减去两端圆角调整)
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi + angleAdjustment,
      math.pi - 2 * angleAdjustment,
      false,
      backgroundPaint,
    );

    // 进度圆弧
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = progressColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      final maxSweepAngle = math.pi - 2 * angleAdjustment;
      final sweepAngle = maxSweepAngle * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi + angleAdjustment,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // 绘制指针三角形
    final adjustedProgress = progress.clamp(0.0, 1.0);
    final pointerAngle =
        math.pi +
        angleAdjustment +
        ((math.pi - 2 * angleAdjustment) * adjustedProgress);

    final pointerPaint =
        Paint()
          ..color = isDark ? Colors.white : Colors.grey.shade800
          ..style = PaintingStyle.fill;

    final pointerSize = 6.0;

    // 保存画布状态
    canvas.save();

    // 将画布原点移动到指针在圆弧上的位置
    // 指针应该在进度条外侧，所以半径加上半个笔画宽度
    final pointerRadius = radius - pointerSize - strokeWidth / 2;
    final pointerX = center.dx + math.cos(pointerAngle) * pointerRadius;
    final pointerY = center.dy + math.sin(pointerAngle) * pointerRadius;
    canvas.translate(pointerX, pointerY);

    // 旋转画布，使三角形指向正确方向
    // pointerAngle 是弧度，需要转换为度数
    // 加上 90 度让三角形尖角指向外侧（远离圆心）
    final angleInDegrees = (pointerAngle * 180 / math.pi) + 90;
    canvas.rotate(angleInDegrees * math.pi / 180);

    // 绘制向上的三角形
    final pointerPath = Path();
    pointerPath.moveTo(0, -pointerSize); // 顶点（尖角）
    pointerPath.lineTo(-pointerSize, pointerSize); // 左下角
    pointerPath.lineTo(pointerSize, pointerSize); // 右下角
    pointerPath.close();

    canvas.drawPath(pointerPath, pointerPaint);

    // 恢复画布状态
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.isDark != isDark;
  }
}
