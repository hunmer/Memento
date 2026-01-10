import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 多指标进度跟踪卡片示例
class MultiMetricProgressCardExample extends StatelessWidget {
  const MultiMetricProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('多指标进度跟踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F4F8),
        child: const Center(
          child: MultiMetricProgressCardWidget(
            title: 'Calories',
            titleIcon: '🔥',
            currentValue: 470,
            targetValue: 1830,
            unit: 'Cal',
            remainingText: '1,360 Cal remaining',
            metrics: [
              MetricData(
                icon: '🍔',
                label: 'Protein',
                value: 66,
                maxValue: 110,
                color: Color(0xFF34D399),
              ),
              MetricData(
                icon: '🍽️',
                label: 'Fasting',
                value: 1,
                maxValue: 16,
                color: Color(0xFFF87171),
                isGray: true,
              ),
              MetricData(
                icon: '🍪',
                label: 'Carbs',
                value: 35,
                maxValue: 88,
                color: Color(0xFFFBBF24),
              ),
              MetricData(
                icon: '🥦',
                label: 'Vegetables',
                value: 230,
                maxValue: 287,
                color: Color(0xFF34D399),
              ),
              MetricData(
                icon: '🥛',
                label: 'Fats',
                value: 210,
                maxValue: 300,
                color: Color(0xFF60A5FA),
              ),
              MetricData(
                icon: '🍉',
                label: 'Fruits',
                value: 130,
                maxValue: 260,
                color: Color(0xFFFBBF24),
              ),
              MetricData(
                icon: '🧂',
                label: 'Sodium',
                value: 120,
                maxValue: 2400,
                color: Color(0xFF9CA3AF),
              ),
              MetricData(
                icon: '🪵',
                label: 'Fiber',
                value: 90,
                maxValue: 1800,
                color: Color(0xFF9CA3AF),
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
  /// 图标（Emoji 或图标名称）
  final String icon;

  /// 标签文本
  final String label;

  /// 当前值
  final double value;

  /// 最大值（用于计算进度）
  final double maxValue;

  /// 进度条颜色
  final Color color;

  /// 是否使用灰色显示（禁用状态）
  final bool isGray;

  const MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.isGray = false,
  });
}

/// 多指标进度跟踪小组件
class MultiMetricProgressCardWidget extends StatefulWidget {
  /// 标题文本
  final String title;

  /// 标题图标（Emoji）
  final String titleIcon;

  /// 当前主指标值
  final double currentValue;

  /// 目标主指标值
  final double targetValue;

  /// 数值单位
  final String unit;

  /// 剩余量文本
  final String remainingText;

  /// 子指标列表
  final List<MetricData> metrics;

  const MultiMetricProgressCardWidget({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.remainingText,
    required this.metrics,
  });

  @override
  State<MultiMetricProgressCardWidget> createState() =>
      _MultiMetricProgressCardWidgetState();
}

class _MultiMetricProgressCardWidgetState
    extends State<MultiMetricProgressCardWidget>
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
    final cardColor = isDark ? const Color(0xFF2C2D31) : Colors.white;
    final primaryColor = isDark
        ? const Color(0xFFFF6B6B)
        : Theme.of(context).colorScheme.primary;
    final textColorPrimary =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final textColorSecondary = const Color(0xFF9CA3AF);

    final progress = widget.currentValue / widget.targetValue;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 主指标部分
                  _buildMainMetricSection(
                    isDark: isDark,
                    primaryColor: primaryColor,
                    textColorPrimary: textColorPrimary,
                    textColorSecondary: textColorSecondary,
                    progress: progress,
                  ),
                  const SizedBox(height: 32),
                  // 子指标网格
                  _buildMetricsGrid(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainMetricSection({
    required bool isDark,
    required Color primaryColor,
    required Color textColorPrimary,
    required Color textColorSecondary,
    required double progress,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Text(
              widget.titleIcon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColorSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 数值显示
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 52,
                child: AnimatedFlipCounter(
                  value: widget.currentValue * _animation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textColorPrimary,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 22,
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColorPrimary,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 进度条
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress * _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 剩余量文本
        Text(
          widget.remainingText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryColor.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(bool isDark) {
    final backgroundColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 32,
        mainAxisSpacing: 28,
        childAspectRatio: 2.8,
      ),
      itemCount: widget.metrics.length,
      itemBuilder: (context, index) {
        final metric = widget.metrics[index];

        // 为每个元素创建延迟动画
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.08,
            0.5 + index * 0.08,
            curve: Curves.easeOutCubic,
          ),
        );

        return _MetricItemWidget(
          metric: metric,
          backgroundColor: backgroundColor,
          animation: itemAnimation,
          isDark: isDark,
        );
      },
    );
  }
}

/// 子指标项组件
class _MetricItemWidget extends StatelessWidget {
  final MetricData metric;
  final Color backgroundColor;
  final Animation<double> animation;
  final bool isDark;

  const _MetricItemWidget({
    required this.metric,
    required this.backgroundColor,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = metric.value / metric.maxValue;
    final textColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final displayColor = metric.isGray
        ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
        : metric.color;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animation.value)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标签和数值行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 图标和标签
                    Row(
                      children: [
                        Text(
                          metric.icon,
                          style: TextStyle(
                            fontSize: 18,
                            color: metric.isGray
                                ? textColor.withOpacity(0.5)
                                : textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          metric.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    // 数值
                    SizedBox(
                      height: 20,
                      child: AnimatedFlipCounter(
                        value: metric.value * animation.value,
                        fractionDigits: metric.value % 1 != 0 ? 1 : 0,
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: displayColor,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 进度条
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress * animation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: displayColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
