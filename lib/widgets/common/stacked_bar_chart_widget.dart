import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 堆叠条形图小组件
///
/// 用于显示分层的堆叠条形图，支持三层数据（浅色、中间色、深色），
/// 每个条形独立动画，适用于统计、对比、趋势分析等场景。
///
/// 特性：
/// - 三层堆叠数据展示（浅色/中间色/深色）
/// - 入场动画（渐入+向上位移）
/// - 独立条形延迟动画
/// - 深色模式适配
/// - 可配置颜色
class StackedBarChartWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 卡片副标题
  final String subtitle;

  /// 增长率百分比
  final double growthRate;

  /// 条形图数据
  final List<StackedBarData> data;

  /// 浅色层颜色
  final Color? lightColor;

  /// 中间层颜色
  final Color? midColor;

  /// 深色层颜色
  final Color? darkColor;

  /// 卡片宽度
  final double? width;

  /// 卡片高度
  final double? height;

  const StackedBarChartWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.growthRate,
    required this.data,
    this.lightColor,
    this.midColor,
    this.darkColor,
    this.width,
    this.height,
  });

  @override
  State<StackedBarChartWidget> createState() => _StackedBarChartWidgetState();
}

class _StackedBarChartWidgetState extends State<StackedBarChartWidget>
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

    // 颜色定义（适配主题）
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final growthColor = isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0EA5E9); // Sky blue - 使用主题色

    // 条形图颜色
    final barLightColor = widget.lightColor ??
        (isDark ? const Color(0xFFBAE6FD) : const Color(0xFFCCEFF9));
    final barMidColor = widget.midColor ??
        (isDark ? const Color(0xFF0284C7) : const Color(0xFF0064A7));
    final barDarkColor = widget.darkColor ??
        (isDark ? const Color(0xFF0C4A6E) : const Color(0xFF000045));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.width ?? 320,
              height: widget.height ?? 360,
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    _buildTitleRow(context, titleColor, growthColor),
                    const SizedBox(height: 32),
                    // 副标题
                    _buildSubtitle(subtitleColor),
                    const SizedBox(height: 32),
                    // 条形图
                    Expanded(
                      child: _buildBars(barLightColor, barMidColor, barDarkColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题行
  Widget _buildTitleRow(BuildContext context, Color titleColor, Color growthColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // 条形图标
        SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 6,
                height: 12,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 6,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const Spacer(),
        // 增长率
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 20,
                color: growthColor,
              ),
              const SizedBox(width: 4),
              AnimatedFlipCounter(
                value: widget.growthRate * _animation.value,
                fractionDigits: 0,
                prefix: '+',
                suffix: '%',
                textStyle: TextStyle(
                  color: growthColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建副标题
  Widget _buildSubtitle(Color subtitleColor) {
    return Text(
      widget.subtitle,
      style: TextStyle(
        fontSize: 14,
        color: subtitleColor,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建条形图区域
  Widget _buildBars(Color lightColor, Color midColor, Color darkColor) {
    return Row(
      children: List.generate(widget.data.length, (index) {
        final barData = widget.data[index];

        // 为每个条形创建延迟动画，确保 end <= 1.0
        final step = 0.05; // 延迟步长，最大 end = 0.6 + 7 * 0.05 = 0.95
        final barAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * step,
            0.6 + index * step,
            curve: Curves.easeOutCubic,
          ),
        );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < widget.data.length - 1 ? 4 : 0,
            ),
            child: _StackedBar(
              data: barData,
              animation: barAnimation,
              lightColor: lightColor,
              midColor: midColor,
              darkColor: darkColor,
            ),
          ),
        );
      }),
    );
  }
}

/// 单个堆叠条形
class _StackedBar extends StatelessWidget {
  final StackedBarData data;
  final Animation<double> animation;
  final Color lightColor;
  final Color midColor;
  final Color darkColor;

  const _StackedBar({
    required this.data,
    required this.animation,
    required this.lightColor,
    required this.midColor,
    required this.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 浅色层
            Container(
              height: (data.lightValue / 100) * 180 * animation.value,
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // 中间层
            Container(
              height: (data.midValue / 100) * 180 * animation.value,
              decoration: BoxDecoration(
                color: midColor,
              ),
            ),
            const SizedBox(height: 2),
            // 深色层
            Container(
              height: (data.darkValue / 100) * 180 * animation.value,
              decoration: BoxDecoration(
                color: darkColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 堆叠条形数据模型
///
/// 表示单个条形的三层数据结构。
class StackedBarData {
  /// 浅色层高度百分比 (0-100)
  final double lightValue;

  /// 中间层高度百分比 (0-100)
  final double midValue;

  /// 深色层高度百分比 (0-100)
  final double darkValue;

  const StackedBarData({
    required this.lightValue,
    required this.midValue,
    required this.darkValue,
  });
}
