import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 双柱状图统计卡片示例
class DualBarChartCardExample extends StatelessWidget {
  const DualBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('双柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DualBarChartCardWidget(
            title: '血压监测',
            date: 'Jan 12, 2028',
            primaryValue: 129,
            secondaryValue: 68,
            primaryLabel: 'sys',
            secondaryLabel: 'dia',
            warningStage: 'Stage 2',
            chartData: [
              DualBarData(primary: 32, secondary: 24),
              DualBarData(primary: 12, secondary: 32),
              DualBarData(primary: 20, secondary: 16),
              DualBarData(primary: 32, secondary: 28),
              DualBarData(primary: 36, secondary: 40),
              DualBarData(primary: 44, secondary: 40),
              DualBarData(primary: 16, secondary: 32),
              DualBarData(primary: 40, secondary: 28),
              DualBarData(primary: 32, secondary: 36),
              DualBarData(primary: 16, secondary: 48),
              DualBarData(primary: 8, secondary: 56),
              DualBarData(primary: 24, secondary: 32),
              DualBarData(primary: 36, secondary: 28),
              DualBarData(primary: 20, secondary: 36),
              DualBarData(primary: 36, secondary: 36),
              DualBarData(primary: 8, secondary: 28),
              DualBarData(primary: 24, secondary: 36),
              DualBarData(primary: 36, secondary: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 双柱状数据模型
class DualBarData {
  final double primary;
  final double secondary;

  const DualBarData({
    required this.primary,
    required this.secondary,
  });
}

/// 双柱状图统计卡片小组件
class DualBarChartCardWidget extends StatefulWidget {
  final String title;
  final String date;
  final int primaryValue;
  final int secondaryValue;
  final String primaryLabel;
  final String secondaryLabel;
  final String? warningStage;
  final List<DualBarData> chartData;

  const DualBarChartCardWidget({
    super.key,
    required this.title,
    required this.date,
    required this.primaryValue,
    required this.secondaryValue,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.warningStage,
    required this.chartData,
  });

  @override
  State<DualBarChartCardWidget> createState() => _DualBarChartCardWidgetState();
}

class _DualBarChartCardWidgetState extends State<DualBarChartCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图表区域
                    SizedBox(
                      height: 128,
                      child: _buildChart(context, primaryColor),
                    ),
                    const SizedBox(height: 24),
                    // 数值显示区域
                    _buildValues(context, primaryColor),
                    const SizedBox(height: 12),
                    // 底部信息区域
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = 0.03;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: widget.chartData.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final data = widget.chartData[index];
        // 确保 Interval 的 end 值不超过 1.0
        final start = (index * step).clamp(0.0, 0.95);
        final end = (0.5 + index * step).clamp(0.0, 1.0);

        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return _DualBarColumn(
          primaryHeight: data.primary,
          secondaryHeight: data.secondary,
          primaryColor: primaryColor,
          secondaryColor: isDark
              ? Colors.grey.shade600.withOpacity(0.3)
              : Colors.grey.shade400.withOpacity(0.4),
          animation: itemAnimation,
        );
      },
    );
  }

  Widget _buildValues(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary value
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 40,
                    child: AnimatedFlipCounter(
                      value: widget.primaryValue * _animation.value,
                      textStyle: TextStyle(
                        fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: Text(
                  widget.primaryLabel,
                  style: TextStyle(
                    fontSize: 18,
                    color: subTextColor,
                    height: 1.0,
                  ),
                ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Secondary value
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade600.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 40,
                    child: AnimatedFlipCounter(
                      value: widget.secondaryValue * _animation.value,
                      textStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: Text(
                      widget.secondaryLabel,
                      style: TextStyle(
                        fontSize: 18,
                        color: subTextColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                widget.date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              if (widget.warningStage != null) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.warningStage!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right,
              size: 28,
              color: isDark
                  ? Colors.grey.shade600.withOpacity(0.4)
                  : Colors.grey.shade400.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 双柱列组件
class _DualBarColumn extends StatelessWidget {
  final double primaryHeight;
  final double secondaryHeight;
  final Color primaryColor;
  final Color secondaryColor;
  final Animation<double> animation;

  const _DualBarColumn({
    required this.primaryHeight,
    required this.secondaryHeight,
    required this.primaryColor,
    required this.secondaryColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Primary bar (top)
              Container(
                width: 8,
                height: primaryHeight * animation.value,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              // Secondary bar (bottom)
              Container(
                width: 8,
                height: secondaryHeight * animation.value,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
