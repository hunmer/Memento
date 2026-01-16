import 'package:flutter/material.dart';

/// 双数值追踪卡片
///
/// 用于显示两个关联数值和趋势的卡片组件，适用于血压、血糖、
/// 体重等需要同时展示两个数值的健康指标追踪。
///
/// 特性：
/// - 双数值显示（如收缩压/舒张压）
/// - 入场计数动画
/// - 深色模式适配
/// - 周趋势柱状图
/// - 可配置颜色和图标
/// - 支持自定义标签和单位
///
/// 示例用法：
/// ```dart
/// // 血压追踪
/// DualValueTrackerCard(
///   title: 'Blood Pressure',
///   primaryValue: 128,
///   secondaryValue: 80,
///   status: 'Stable Range',
///   unit: 'mmHg',
///   icon: Icons.water_drop,
///   weekData: [
///     WeekData(label: 'M', normalPercent: 0.60, elevatedPercent: 0.20),
///     WeekData(label: 'T', normalPercent: 0.70, elevatedPercent: 0.30),
///   ],
/// )
///
/// // 血糖追踪
/// DualValueTrackerCard(
///   title: 'Blood Sugar',
///   primaryValue: 5.8,
///   secondaryValue: 6.2,
///   status: 'Normal',
///   unit: 'mmol/L',
///   icon: Icons.bloodtype,
///   decimalPlaces: 1,
/// )
/// ```
class DualValueTrackerCard extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 主数值（如收缩压、空腹血糖）
  final double primaryValue;

  /// 次数值（如舒张压、餐后血糖）
  final double secondaryValue;

  /// 状态描述
  final String? status;

  /// 单位
  final String unit;

  /// 图标
  final IconData icon;

  /// 主色调
  final Color? primaryColor;

  /// 小数位数（用于显示浮点数）
  final int decimalPlaces;

  /// 周数据
  final List<WeekData> weekData;

  /// 是否显示右侧按钮
  final bool showActionButton;

  /// 动作按钮标签
  final String? actionLabel;

  /// 动作按钮点击回调
  final VoidCallback? onActionPressed;

  /// 卡片宽度
  final double? width;

  const DualValueTrackerCard({
    super.key,
    required this.title,
    required this.primaryValue,
    required this.secondaryValue,
    this.status,
    required this.unit,
    required this.icon,
    this.primaryColor,
    this.decimalPlaces = 0,
    required this.weekData,
    this.showActionButton = true,
    this.actionLabel,
    this.onActionPressed,
    this.width,
  });

  @override
  State<DualValueTrackerCard> createState() => _DualValueTrackerCardState();
}

class _DualValueTrackerCardState extends State<DualValueTrackerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
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
    return FadeTransition(
      opacity: _animationController,
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widget.width ?? 350,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(context),
          const SizedBox(height: 32),
          // 数值和趋势图
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        if (widget.showActionButton)
          TextButton.icon(
            onPressed: widget.onActionPressed,
            icon: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
            label: Text(
              widget.actionLabel ?? 'Today',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // 双数值显示
        _buildDualValue(context),
        const SizedBox(height: 16),
        // 周趋势图
        _buildWeekTrendChart(context),
      ],
    );
  }

  Widget _buildDualValue(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // 主数值
            AnimatedCountText(
              count: widget.primaryValue,
              duration: const Duration(milliseconds: 1000),
              decimalPlaces: widget.decimalPlaces,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: primaryColor,
                  ),
            ),
            Text(
              '/',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: primaryColor,
                  ),
            ),
            // 次数值
            AnimatedCountText(
              count: widget.secondaryValue,
              duration: const Duration(milliseconds: 1000),
              decimalPlaces: widget.decimalPlaces,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.unit,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 状态描述
        if (widget.status != null)
          Text(
            widget.status!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
      ],
    );
  }

  Widget _buildWeekTrendChart(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.weekData.map((dayData) {
          return WeekBar(
            label: dayData.label,
            normalPercent: dayData.normalPercent,
            elevatedPercent: dayData.elevatedPercent,
            animationController: _animationController,
            primaryColor: widget.primaryColor,
          );
        }).toList(),
      ),
    );
  }
}

/// 周数据柱状图组件
class WeekBar extends StatelessWidget {
  final String label;
  final double normalPercent;
  final double elevatedPercent;
  final AnimationController animationController;
  final Color? primaryColor;

  const WeekBar({
    super.key,
    required this.label,
    required this.normalPercent,
    required this.elevatedPercent,
    required this.animationController,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = primaryColor ?? colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 柱状图
        SizedBox(
          height: 48,
          width: 8,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 背景条
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // 正常范围条（浅色）
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    heightFactor: normalPercent * animationController.value,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
              // 升高范围条（深色）
              Positioned(
                bottom: (normalPercent - elevatedPercent) * 48,
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return SizedBox(
                      height: elevatedPercent * 48 * animationController.value,
                      width: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 标签
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

/// 数字计数动画组件
class AnimatedCountText extends StatefulWidget {
  final double count;
  final Duration duration;
  final int decimalPlaces;
  final TextStyle? style;

  const AnimatedCountText({
    super.key,
    required this.count,
    required this.duration,
    this.decimalPlaces = 0,
    this.style,
  });

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.count).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final displayValue = widget.decimalPlaces > 0
            ? value.toStringAsFixed(widget.decimalPlaces)
            : value.toInt().toString();
        return Text(
          displayValue,
          style: widget.style,
        );
      },
    );
  }
}

/// 周数据模型
///
/// 表示一周中某一天的数据，用于柱状图展示。
class WeekData {
  /// 标签（如 'M', 'T', 'W' 或周一、周二）
  final String label;

  /// 正常范围百分比 (0.0-1.0)
  final double normalPercent;

  /// 升高范围百分比 (0.0-1.0)
  final double elevatedPercent;

  const WeekData({
    required this.label,
    required this.normalPercent,
    required this.elevatedPercent,
  });

  /// 创建默认的空数据
  factory WeekData.empty(String label) {
    return WeekData(
      label: label,
      normalPercent: 0.0,
      elevatedPercent: 0.0,
    );
  }

  /// 从 JSON 创建
  factory WeekData.fromJson(Map<String, dynamic> json) {
    return WeekData(
      label: json['label'] as String,
      normalPercent: (json['normalPercent'] as num?)?.toDouble() ?? 0.0,
      elevatedPercent: (json['elevatedPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'normalPercent': normalPercent,
      'elevatedPercent': elevatedPercent,
    };
  }
}

/// 双数值追踪卡片包装器（用于 widgets_gallery 兼容性）
///
/// 提供从 props 创建实例的工厂方法，用于公共小组件系统。
class DualValueTrackerCardWrapper extends StatelessWidget {
  /// 卡片标题
  final String title;

  /// 主数值
  final double primaryValue;

  /// 次数值
  final double secondaryValue;

  /// 状态描述
  final String? status;

  /// 单位
  final String unit;

  /// 图标代码
  final String icon;

  /// 主色调
  final Color? primaryColor;

  /// 小数位数
  final int decimalPlaces;

  /// 周数据
  final List<WeekData> weekData;

  const DualValueTrackerCardWrapper({
    super.key,
    required this.title,
    required this.primaryValue,
    required this.secondaryValue,
    this.status,
    required this.unit,
    required this.icon,
    this.primaryColor,
    this.decimalPlaces = 0,
    required this.weekData,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DualValueTrackerCardWrapper.fromProps(
    Map<String, dynamic> props,
  ) {
    final weekDataList = props['weekData'] as List?;
    final weekData = weekDataList?.map((item) {
      return WeekData.fromJson(item as Map<String, dynamic>);
    }).toList() ?? <WeekData>[];

    return DualValueTrackerCardWrapper(
      title: props['title'] as String? ?? '统计',
      primaryValue: (props['primaryValue'] as num?)?.toDouble() ?? 0.0,
      secondaryValue: (props['secondaryValue'] as num?)?.toDouble() ?? 0.0,
      status: props['status'] as String?,
      unit: props['unit'] as String? ?? '',
      icon: props['icon'] as String? ?? 'info',
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
      decimalPlaces: props['decimalPlaces'] as int? ?? 0,
      weekData: weekData,
    );
  }

  IconData _getIconData(String iconCode) {
    // 简化的图标映射
    switch (iconCode) {
      case 'water_drop':
        return Icons.water_drop;
      case 'favorite':
        return Icons.favorite;
      case 'timeline':
        return Icons.timeline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DualValueTrackerCard(
      title: title,
      primaryValue: primaryValue,
      secondaryValue: secondaryValue,
      status: status,
      unit: unit,
      icon: _getIconData(icon),
      primaryColor: primaryColor,
      decimalPlaces: decimalPlaces,
      weekData: weekData,
      showActionButton: false,
    );
  }
}
