import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 垂直条形图卡片
///
/// 用于显示带标题、图标和数值的垂直条形图，支持动画效果，
/// 适用于天气统计、数据分析、趋势展示等场景。
///
/// 特性：
/// - 自定义图标和颜色
/// - 数值动画（使用 AnimatedFlipCounter）
/// - 入场动画（渐入+向上位移）
/// - 独立条形延迟动画
/// - 深色模式适配
/// - 可配置条形数据
class VerticalBarChartCard extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 卡片图标
  final IconData icon;

  /// 图标背景色
  final Color iconBackgroundColor;

  /// 图标颜色
  final Color iconColor;

  /// 副标题（如地点名称）
  final String subtitle;

  /// 主标题（如天气状态）
  final String headline;

  /// 当前数值
  final double value;

  /// 最小值
  final double minValue;

  /// 数值单位
  final String unit;

  /// 条形图数据
  final List<VerticalBarData> barData;

  /// 卡片宽度
  final double? width;

  const VerticalBarChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.subtitle,
    required this.headline,
    required this.value,
    required this.minValue,
    this.unit = '',
    required this.barData,
    this.width,
  });

  @override
  State<VerticalBarChartCard> createState() => _VerticalBarChartCardState();
}

class _VerticalBarChartCardState extends State<VerticalBarChartCard>
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final headlineColor = isDark ? Colors.white : const Color(0xFF111827);
    final valueColor = isDark ? Colors.white : const Color(0xFF111827);
    final minValueColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.width ?? 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
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
                children: [
                  // Header
                  _HeaderWidget(
                    title: widget.title,
                    icon: widget.icon,
                    iconBackgroundColor: widget.iconBackgroundColor,
                    iconColor: widget.iconColor,
                  ),
                  const SizedBox(height: 16),

                  // Info section
                  _InfoWidget(
                    subtitle: widget.subtitle,
                    headline: widget.headline,
                    value: widget.value,
                    minValue: widget.minValue,
                    unit: widget.unit,
                    subtitleColor: subtitleColor,
                    headlineColor: headlineColor,
                    valueColor: valueColor,
                    minValueColor: minValueColor,
                    animation: _animation,
                  ),
                  const SizedBox(height: 32),

                  // Bar chart
                  _BarChartWidget(
                    barData: widget.barData,
                    animation: _animation,
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

/// 头部组件
class _HeaderWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;

  const _HeaderWidget({
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? iconColor.withOpacity(0.2)
                    : iconBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isDark ? iconColor.withOpacity(0.8) : iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _IconButton(icon: Icons.chevron_left),
            const SizedBox(width: 8),
            _IconButton(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }
}

/// 图标按钮
class _IconButton extends StatelessWidget {
  final IconData icon;

  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        size: 20,
      ),
    );
  }
}

/// 信息组件
class _InfoWidget extends StatelessWidget {
  final String subtitle;
  final String headline;
  final double value;
  final double minValue;
  final String unit;
  final Color subtitleColor;
  final Color headlineColor;
  final Color valueColor;
  final Color minValueColor;
  final Animation<double> animation;

  const _InfoWidget({
    required this.subtitle,
    required this.headline,
    required this.value,
    required this.minValue,
    required this.unit,
    required this.subtitleColor,
    required this.headlineColor,
    required this.valueColor,
    required this.minValueColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subtitle,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          headline,
          style: TextStyle(
            color: headlineColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 30,
                    child: AnimatedFlipCounter(
                      value: value * animation.value,
                      fractionDigits: value % 1 != 0 ? 1 : 0,
                      textStyle: TextStyle(
                        color: valueColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 20,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 20,
              child: Text(
                '$minValue$unit',
                style: TextStyle(
                  color: minValueColor,
                  fontSize: 20,
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

/// 条形图组件
class _BarChartWidget extends StatelessWidget {
  final List<VerticalBarData> barData;
  final Animation<double> animation;

  const _BarChartWidget({
    required this.barData,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < barData.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _BarItem(
              data: barData[i],
              animation: animation,
              index: i,
            ),
          ],
        ],
      ),
    );
  }
}

/// 单个条形组件
class _BarItem extends StatelessWidget {
  final VerticalBarData data;
  final Animation<double> animation;
  final int index;

  const _BarItem({
    required this.data,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final end = (0.4 + index * 0.07).clamp(0.0, 1.0);
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.07,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return Container(
      width: 12,
      height: 64,
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: itemAnimation,
        builder: (context, child) {
          return Container(
            width: 12,
            height: 64 * data.height * itemAnimation.value.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        },
      ),
    );
  }
}

/// 垂直条形数据模型
///
/// 表示单个条形的数据结构。
class VerticalBarData {
  /// 条形高度百分比 (0.0-1.0)
  final double height;

  /// 条形颜色
  final Color color;

  /// 是否为当前选中状态
  final bool isCurrent;

  const VerticalBarData({
    required this.height,
    required this.color,
    this.isCurrent = false,
  });
}
