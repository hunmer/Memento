import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 月度进度圆点小组件
class MonthlyProgressWithDotsCardWidget extends StatefulWidget {
  /// 标题（如习惯名称）
  final String title;

  /// 副标题（如月份、状态描述）
  final String? subtitle;

  /// 当前天数
  final int currentDay;

  /// 总天数
  final int totalDays;

  /// 百分比
  final int percentage;

  /// 背景颜色
  final Color backgroundColor;

  /// 已过日期的颜色（圆点颜色）
  final Color? activeDotColor;

  /// 未过日期的颜色（圆点颜色）
  final Color? inactiveDotColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const MonthlyProgressWithDotsCardWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentDay,
    required this.totalDays,
    required this.percentage,
    required this.backgroundColor,
    this.activeDotColor,
    this.inactiveDotColor,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MonthlyProgressWithDotsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MonthlyProgressWithDotsCardWidget(
      title: props['title'] as String? ?? props['month'] as String? ?? '',
      subtitle: props['subtitle'] as String?,
      currentDay: props['currentDay'] as int? ?? 0,
      totalDays: props['totalDays'] as int? ?? 31,
      percentage: props['percentage'] as int? ?? 0,
      backgroundColor:
          props.containsKey('backgroundColor')
              ? Color(props['backgroundColor'] as int)
              : const Color(0xFF148690),
      activeDotColor:
          props['activeDotColor'] != null
              ? Color(props['activeDotColor'] as int)
              : null,
      inactiveDotColor:
          props['inactiveDotColor'] != null
              ? Color(props['inactiveDotColor'] as int)
              : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<MonthlyProgressWithDotsCardWidget> createState() =>
      _MonthlyProgressWithDotsCardWidgetState();
}

class _MonthlyProgressWithDotsCardWidgetState
    extends State<MonthlyProgressWithDotsCardWidget>
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
    // 颜色定义
    final defaultActiveDotColor = Theme.of(context).colorScheme.primary;
    const defaultInactiveDotColor = Color(0x33FFFFFF);
    final textColor = Theme.of(context).colorScheme.onPrimary;
    final subtitleColor = Theme.of(
      context,
    ).colorScheme.onPrimary.withOpacity(0.6);

    final effectiveActiveDotColor =
        widget.activeDotColor ?? defaultActiveDotColor;
    final effectiveInactiveDotColor =
        widget.inactiveDotColor ?? defaultInactiveDotColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 250,
              height: widget.inline ? double.maxFinite : 250,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: widget.size.getPadding(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 圆点矩阵（3行，每行11个点，代表33天）
                  _DotMatrixGrid(
                    currentDay: widget.currentDay,
                    activeDotColor: effectiveActiveDotColor,
                    inactiveDotColor: effectiveInactiveDotColor,
                    animation: _animation,
                    size: widget.size,
                  ),

                  // 底部信息
                  _buildBottomInfo(textColor, subtitleColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInfo(Color textColor, Color subtitleColor) {
    final infoAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: infoAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: infoAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - infoAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: widget.size.getLargeFontSize() * 0.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: widget.size.getItemSpacing() * 0.25),
                Text(
                  widget.subtitle ??
                      '${widget.currentDay}d/${widget.totalDays}d',
                  style: TextStyle(
                    fontSize: widget.size.getLargeFontSize() * 0.29,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: widget.size.getItemSpacing()),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedFlipCounter(
                      value: widget.percentage.toDouble() * infoAnimation.value,
                      fractionDigits: 0,
                      suffix: '%',
                      textStyle: TextStyle(
                        fontSize: widget.size.getLargeFontSize(),
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 圆点矩阵网格
class _DotMatrixGrid extends StatelessWidget {
  final int currentDay;
  final Color activeDotColor;
  final Color inactiveDotColor;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _DotMatrixGrid({
    required this.currentDay,
    required this.activeDotColor,
    required this.inactiveDotColor,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final dots = _generateDotStates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.only(bottom: size.getItemSpacing() * 0.75),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int col = 0; col < 11; col++)
                  _Dot(
                    isActive: dots[row * 11 + col],
                    activeColor: activeDotColor,
                    inactiveColor: inactiveDotColor,
                    animation: animation,
                    index: row * 11 + col,
                    size: size,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 生成圆点状态列表
  List<bool> _generateDotStates() {
    final List<bool> states = [];
    for (int i = 0; i < 33; i++) {
      states.add(i < currentDay);
    }
    return states;
  }
}

/// 单个圆点
class _Dot extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _Dot({
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final dotAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        (index * 0.02).clamp(0.0, 0.3),
        0.3 + (index * 0.015).clamp(0.0, 0.3),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: dotAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.3 + 0.7 * dotAnimation.value,
          child: Container(
            width: size.getIconSize() * 0.42,
            height: size.getIconSize() * 0.42,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
