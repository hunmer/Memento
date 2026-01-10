import 'dart:math' as math;
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 甜甜圈图统计卡片示例
class DonutChartStatsCardExample extends StatelessWidget {
  const DonutChartStatsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('甜甜圈图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DonutChartStatsCardWidget(
            totalValue: 85964.45,
            unit: '',
            categories: [
              ChartCategoryData(
                label: 'Marketing Channels',
                value: 0.22,
                color: Color(0xFF4F46E5),
              ),
              ChartCategoryData(
                label: 'Direct Sales',
                value: 0.22,
                color: Color(0xFF6EE7B7),
              ),
              ChartCategoryData(
                label: 'Offline Channels',
                value: 0.44,
                color: Color(0xFFFBBF24),
              ),
              ChartCategoryData(
                label: 'Other Channels',
                value: 0.12,
                color: Color(0xFFF472B6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图表分类数据模型
class ChartCategoryData {
  final String label;
  final double value; // 占比 0-1
  final Color color;

  const ChartCategoryData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// 甜甜圈图统计小组件
class DonutChartStatsCardWidget extends StatefulWidget {
  final double totalValue;
  final String unit;
  final List<ChartCategoryData> categories;

  const DonutChartStatsCardWidget({
    super.key,
    required this.totalValue,
    this.unit = '',
    required this.categories,
  });

  @override
  State<DonutChartStatsCardWidget> createState() => _DonutChartStatsCardWidgetState();
}

class _DonutChartStatsCardWidgetState extends State<DonutChartStatsCardWidget>
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
    // 添加监听器确保 UI 更新
    _animationController.addListener(() {
      setState(() {});
    });
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
        width: 384,
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧：圆环图 + 总金额
            Expanded(
              flex: 45,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 甜甜圈图
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          categories: widget.categories,
                          progress: _animation.value,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 总金额
                    Column(
                      children: [
                        SizedBox(
                          height: 28,
                          child: AnimatedFlipCounter(
                            value: widget.totalValue * _animation.value,
                            fractionDigits: 2,
                            textStyle: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 16,
                          child: Text(
                            'Income',
                            style: TextStyle(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
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
            // 右侧：分类列表
            Expanded(
              flex: 55,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: _buildCategoryItems(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(bool isDark) {
    final items = <Widget>[];
    final step = 0.08; // 确保 0.5 + 3 * 0.08 = 0.74 < 1.0

    for (int i = 0; i < widget.categories.length; i++) {
      final category = widget.categories[i];
      final itemAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          i * step,
          0.5 + i * step,
          curve: Curves.easeOutCubic,
        ),
      );

      if (i > 0) {
        items.add(const SizedBox(height: 20));
      }

      items.add(
        AnimatedBuilder(
          animation: itemAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: itemAnimation.value,
              child: Transform.translate(
                offset: Offset(10 * (1 - itemAnimation.value), 0),
                child: _CategoryItem(
                  label: category.label,
                  color: category.color,
                  isDark: isDark,
                ),
              ),
            );
          },
        ),
      );
    }

    return items;
  }
}

/// 分类列表项
class _CategoryItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _CategoryItem({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 颜色指示点
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 标签文本
        SizedBox(
          height: 16,
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

/// 甜甜圈图绘制器
class _DonutChartPainter extends CustomPainter {
  final List<ChartCategoryData> categories;
  final double progress;
  final bool isDark;

  _DonutChartPainter({
    required this.categories,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.56; // 创建环形效果

    // 绘制背景圆环
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 计算总角度（360度）
    final totalAngle = 2 * math.pi;
    var startAngle = -math.pi / 2; // 从顶部开始
    var drawnAngle = 0.0; // 已绘制的角度

    // 绘制每个扇形
    for (final category in categories) {
      final categorySweepAngle = totalAngle * category.value; // 扇形的完整角度
      final remainingAngle = totalAngle * progress - drawnAngle; // 剩余可绘制角度

      if (remainingAngle <= 0) break; // 进度已用完，停止绘制

      // 计算本次要绘制的角度（取扇形完整角度和剩余角度的较小值）
      final sweepAngle = categorySweepAngle < remainingAngle
          ? categorySweepAngle
          : remainingAngle;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill;

      // 绘制扇形（使用 useCenter=true 才能正确绘制扇形）
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += categorySweepAngle; // 使用完整角度更新起始位置
      drawnAngle += sweepAngle; // 累加已绘制的角度
    }

    // 绘制中心白色圆（创建甜甜圈效果）
    final centerPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.categories.length != categories.length;
  }
}
