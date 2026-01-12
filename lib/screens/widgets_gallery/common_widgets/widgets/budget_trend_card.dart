import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 预算趋势卡片小组件
///
/// 通用的带迷你曲线图的数值展示卡片，支持：
/// - 标签和图标
/// - 数值显示（带翻转动画）
/// - 迷你曲线图
/// - 变化百分比
/// - 更新时间
class BudgetTrendCardWidget extends StatefulWidget {
  /// 卡片标签（如 Budget、Expense 等）
  final String label;

  /// 数值
  final double value;

  /// 数值前缀（如 $、¥ 等）
  final String valuePrefix;

  /// 数值后缀（如 % 等）
  final String valueSuffix;

  /// 描述文本
  final String description;

  /// 图表数据（Y坐标值，0-100范围）
  final List<double> chartData;

  /// 变化值
  final double changeValue;

  /// 变化百分比
  final double changePercent;

  /// 更新时间
  final String updateTime;

  const BudgetTrendCardWidget({
    super.key,
    required this.label,
    required this.value,
    this.valuePrefix = '',
    this.valueSuffix = '',
    required this.description,
    required this.chartData,
    required this.changeValue,
    required this.changePercent,
    required this.updateTime,
  });

  /// 从 props 创建实例
  factory BudgetTrendCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return BudgetTrendCardWidget(
      label: props['label'] as String? ?? 'Budget',
      value: (props['value'] as num?)?.toDouble() ?? 0,
      valuePrefix: props['valuePrefix'] as String? ?? '',
      valueSuffix: props['valueSuffix'] as String? ?? '',
      description: props['description'] as String? ?? '',
      chartData: (props['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      changeValue: (props['changeValue'] as num?)?.toDouble() ?? 0,
      changePercent: (props['changePercent'] as num?)?.toDouble() ?? 0,
      updateTime: props['updateTime'] as String? ?? '',
    );
  }

  @override
  State<BudgetTrendCardWidget> createState() => _BudgetTrendCardWidgetState();
}

class _BudgetTrendCardWidgetState extends State<BudgetTrendCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
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
    // 根据变化百分比的符号确定颜色和图标
    final isPositive = widget.changePercent >= 0;
    final primaryColor =
        isPositive ? const Color(0xFF34D399) : const Color(0xFFF43F5E);
    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF);
    final borderColor =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标签
                  _buildLabel(context, subTextColor),
                  const SizedBox(height: 24),

                  // 数值和图表区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 数值显示
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 数值和箭头
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // 前缀
                                      if (widget.valuePrefix.isNotEmpty) ...[
                                        SizedBox(
                                          height: 30,
                                          child: Text(
                                            widget.valuePrefix,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                      ],
                                      // 数值
                                      SizedBox(
                                        width: 140,
                                        height: 38,
                                        child: AnimatedFlipCounter(
                                          value:
                                              widget.value *
                                              _fadeInAnimation.value,
                                          fractionDigits:
                                              widget.value % 1 != 0 ? 2 : 0,
                                          textStyle: TextStyle(
                                            color: textColor,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                      // 后缀
                                      if (widget.valueSuffix.isNotEmpty) ...[
                                        const SizedBox(width: 2),
                                        SizedBox(
                                          height: 22,
                                          child: Text(
                                            widget.valueSuffix,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // 趋势箭头图标
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationZ(isPositive ? -0.3 : 0.3),
                                  child: Icon(
                                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // 描述
                            SizedBox(
                              height: 20,
                              child: Text(
                                widget.description,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 迷你曲线图
                      _buildMiniChart(primaryColor, borderColor),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 底部信息（变化百分比和更新时间）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 变化百分比
                      SizedBox(
                        height: 18,
                        child: Text(
                          '${isPositive ? '+' : '-'}${widget.changeValue.abs()} (${widget.changePercent.abs().toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                      ),

                      // 更新时间
                      SizedBox(
                        height: 18,
                        child: Text(
                          widget.updateTime,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标签行
  Widget _buildLabel(BuildContext context, Color subTextColor) {
    return Row(
      children: [
        Icon(Icons.schedule, color: subTextColor, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          height: 16,
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建迷你曲线图
  Widget _buildMiniChart(Color primaryColor, Color borderColor) {
    return SizedBox(
      width: 100,
      height: 48,
      child: Stack(
        children: [
          // 虚线分隔线
          Positioned(
            top: 26,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ),
          // 曲线图
          CustomPaint(
            size: const Size(100, 48),
            painter: _MiniChartPainter(
              data: widget.chartData,
              primaryColor: primaryColor,
              animationValue: _fadeInAnimation.value,
            ),
          ),
        ],
      ),
    );
  }
}

/// 迷你曲线图绘制器
class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color primaryColor;
  final double animationValue;

  _MiniChartPainter({
    required this.data,
    required this.primaryColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final pointDistance = size.width / (data.length - 1);
    final path = Path();

    // 移动到第一个点
    final firstY = size.height - (data[0] / 100 * size.height * animationValue);
    path.moveTo(0, firstY);

    // 绘制平滑曲线
    for (int i = 0; i < data.length; i++) {
      final x = i * pointDistance;
      final y = size.height - (data[i] / 100 * size.height * animationValue);

      if (i > 0) {
        final prevX = (i - 1) * pointDistance;
        final prevY =
            size.height - (data[i - 1] / 100 * size.height * animationValue);

        // 使用三次贝塞尔曲线创建平滑效果
        final cp1x = prevX + (x - prevX) / 3;
        final cp1y = prevY;
        final cp2x = prevX + 2 * (x - prevX) / 3;
        final cp2y = y;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
      }
    }

    // 绘制曲线
    final paint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor;
  }
}
