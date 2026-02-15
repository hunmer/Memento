import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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

  /// 小组件尺寸
  final HomeWidgetSize size;

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
    this.size = const MediumSize(),
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
    final size = widget.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 获取卡片的可用高度
        final availableHeight = constraints.maxHeight;
        final hasHeightConstraint =
            availableHeight.isFinite && availableHeight > 0;

        return Container(
          width: widget.width ?? double.infinity,
          padding: size.getPadding(),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: size.getIconSize(),
                offset: Offset(0, size.getSmallSpacing()),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              _buildHeader(context),
              // 数值显示
              _buildDualValue(context),
              SizedBox(height: size.getItemSpacing()),
              // 周趋势图 - 填满剩余空间
              if (hasHeightConstraint)
                Expanded(
                  child: _buildWeekTrendChart(
                    context,
                    availableChartHeight: _calculateAvailableChartHeight(
                      availableHeight,
                      size,
                    ),
                  ),
                )
              else
                _buildWeekTrendChart(context, availableChartHeight: null),
            ],
          ),
        );
      },
    );
  }

  /// 计算柱状图可用高度
  double _calculateAvailableChartHeight(
    double totalHeight,
    HomeWidgetSize size,
  ) {
    final padding = size.getPadding();
    final headerHeight =
        size.getIconSize() + size.getSmallSpacing() * 4; // 图标容器 + padding
    final valueFontSize = size.getLargeFontSize() * 0.5;
    final valueHeight = valueFontSize * 1.5; // 数值行高度
    final statusHeight =
        size.getSmallSpacing() + size.getLegendFontSize() * 1.2; // 状态文本高度
    final itemSpacing = size.getItemSpacing();

    // 可用高度 = 总高度 - padding - 标题 - 数值 - 状态 - 间距
    final usedHeight =
        padding.top +
        padding.bottom +
        headerHeight +
        valueHeight +
        statusHeight +
        itemSpacing;
    final available = totalHeight - usedHeight;
    return available > 0 ? available : size.getIconSize() * 2; // 最小高度保底
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;
    final size = widget.size;
    final iconSize = size.getIconSize();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(size.getSmallSpacing() * 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconSize * 0.5),
                ),
                child: Icon(widget.icon, color: primaryColor, size: iconSize),
              ),
              SizedBox(width: size.getSmallSpacing() * 3),
              Flexible(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: size.getTitleFontSize(),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        if (widget.showActionButton)
          TextButton.icon(
            onPressed: widget.onActionPressed,
            icon: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.5),
              size: iconSize * 0.8,
            ),
            label: Text(
              widget.actionLabel ?? 'Today',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: size.getSubtitleFontSize(),
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: size.getSmallSpacing() * 2,
                vertical: size.getSmallSpacing(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDualValue(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;
    final size = widget.size;
    final valueFontSize = size.getLargeFontSize() * 0.5; // 约 18-28px
    final unitFontSize = size.getSubtitleFontSize();
    final statusFontSize = size.getLegendFontSize();

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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: valueFontSize,
                color: primaryColor,
              ),
            ),
            Text(
              '/',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: valueFontSize,
                color: primaryColor,
              ),
            ),
            // 次数值
            AnimatedCountText(
              count: widget.secondaryValue,
              duration: const Duration(milliseconds: 1000),
              decimalPlaces: widget.decimalPlaces,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: valueFontSize,
                color: primaryColor,
              ),
            ),
            SizedBox(width: size.getSmallSpacing()),
            Text(
              widget.unit,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: unitFontSize,
              ),
            ),
          ],
        ),
        // 状态描述
        if (widget.status != null)
          Text(
            widget.status!,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: statusFontSize,
            ),
          ),
      ],
    );
  }

  Widget _buildWeekTrendChart(
    BuildContext context, {
    required double? availableChartHeight,
  }) {
    final size = widget.size;
    final barWidth = size.getBarWidth();
    final labelFontSize = size.getLegendFontSize();
    final spacing = size.getSmallSpacing() * 2;

    // 计算柱状图区域高度
    final labelHeight = labelFontSize * 1.2;
    // 使用传入的可用高度或回退到默认计算
    final maxBarHeight =
        availableChartHeight != null
            ? (availableChartHeight - spacing - labelHeight).clamp(
              size.getIconSize(),
              double.infinity,
            )
            : size.getIconSize() * 2;

    // 找到所有数据中的最大总百分比，用于按比例缩放
    final maxTotalPercent = widget.weekData.fold<double>(
      0.0,
      (max, data) =>
          (data.normalPercent + data.elevatedPercent) > max
              ? data.normalPercent + data.elevatedPercent
              : max,
    );

    return SizedBox(
      height: maxBarHeight + spacing + labelHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            widget.weekData.map((dayData) {
              return WeekBar(
                label: dayData.label,
                normalPercent: dayData.normalPercent,
                elevatedPercent: dayData.elevatedPercent,
                maxTotalPercent: maxTotalPercent,
                animationController: _animationController,
                primaryColor: widget.primaryColor,
                size: size,
                maxBarHeight: maxBarHeight,
                barWidth: barWidth,
                labelFontSize: labelFontSize,
                spacing: spacing,
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
  final double maxTotalPercent;
  final AnimationController animationController;
  final Color? primaryColor;
  final HomeWidgetSize size;
  final double maxBarHeight;
  final double barWidth;
  final double labelFontSize;
  final double spacing;

  const WeekBar({
    super.key,
    required this.label,
    required this.normalPercent,
    required this.elevatedPercent,
    required this.maxTotalPercent,
    required this.animationController,
    this.primaryColor,
    required this.size,
    required this.maxBarHeight,
    required this.barWidth,
    required this.labelFontSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = primaryColor ?? colorScheme.primary;

    // 根据最大百分比计算缩放比例
    final totalPercent = normalPercent + elevatedPercent;
    final scale = maxTotalPercent > 0 ? totalPercent / maxTotalPercent : 0.0;
    final barHeight = maxBarHeight * scale;

    // 柱状图圆角 - 只在顶部有圆角，不是纯圆
    final barRadius = BorderRadius.vertical(top: Radius.circular(barWidth * 0.25));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 柱状图 - 使用 Expanded 让柱子填满可用空间
        SizedBox(
          height: maxBarHeight,
          width: barWidth,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 背景条 - 显示完整的可用高度
              Container(
                width: barWidth,
                height: maxBarHeight,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: barRadius,
                ),
              ),
              // 正常范围条（浅色）
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  final animHeight =
                      totalPercent > 0
                          ? normalPercent *
                              barHeight *
                              animationController.value /
                              totalPercent
                          : 0.0;
                  return SizedBox(
                    height: animHeight,
                    width: barWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.3),
                        borderRadius: barRadius,
                      ),
                    ),
                  );
                },
              ),
              // 升高范围条（深色）
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  final animHeight =
                      totalPercent > 0
                          ? elevatedPercent *
                              barHeight *
                              animationController.value /
                              totalPercent
                          : 0.0;
                  final bottomPosition =
                      totalPercent > 0
                          ? normalPercent * barHeight / totalPercent
                          : 0.0;
                  return Positioned(
                    bottom: bottomPosition,
                    child: SizedBox(
                      height: animHeight,
                      width: barWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: barRadius,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: spacing),
        // 标签
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
            fontSize: labelFontSize,
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
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.count,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
        final displayValue =
            widget.decimalPlaces > 0
                ? value.toStringAsFixed(widget.decimalPlaces)
                : value.toInt().toString();
        return Text(displayValue, style: widget.style);
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
    return WeekData(label: label, normalPercent: 0.0, elevatedPercent: 0.0);
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

  /// 小组件尺寸
  final HomeWidgetSize size;

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
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DualValueTrackerCardWrapper.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final weekDataList = props['weekData'] as List?;
    final weekData =
        weekDataList?.map((item) {
          return WeekData.fromJson(item as Map<String, dynamic>);
        }).toList() ??
        <WeekData>[];

    return DualValueTrackerCardWrapper(
      title: props['title'] as String? ?? '统计',
      primaryValue: (props['primaryValue'] as num?)?.toDouble() ?? 0.0,
      secondaryValue: (props['secondaryValue'] as num?)?.toDouble() ?? 0.0,
      status: props['status'] as String?,
      unit: props['unit'] as String? ?? '',
      icon: props['icon'] as String? ?? 'info',
      primaryColor:
          props['primaryColor'] != null
              ? Color(props['primaryColor'] as int)
              : null,
      decimalPlaces: props['decimalPlaces'] as int? ?? 0,
      weekData: weekData,
      size: size,
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
      size: size,
    );
  }
}
