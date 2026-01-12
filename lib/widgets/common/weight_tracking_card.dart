import 'dart:convert';
import 'package:flutter/material.dart';

/// 体重追踪数据模型
///
/// 用于体重追踪卡片的数据序列化和传输。
class WeightTrackingData {
  /// 当前体重
  final double currentWeight;

  /// 体重变化（正值为增加，负值为减少）
  final double weightChange;

  /// 目标体重（上限警戒线）
  final double targetWeight;

  /// 历史体重数据
  final List<double> data;

  /// 体重单位，默认为 kg
  final String? unit;

  const WeightTrackingData({
    required this.currentWeight,
    required this.weightChange,
    required this.targetWeight,
    required this.data,
    this.unit,
  });

  /// 从 JSON 创建体重追踪数据
  factory WeightTrackingData.fromJson(Map<String, dynamic> json) {
    return WeightTrackingData(
      currentWeight: (json['currentWeight'] as num).toDouble(),
      weightChange: (json['weightChange'] as num).toDouble(),
      targetWeight: (json['targetWeight'] as num).toDouble(),
      data: (json['data'] as List).map((e) => (e as num).toDouble()).toList(),
      unit: json['unit'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'currentWeight': currentWeight,
      'weightChange': weightChange,
      'targetWeight': targetWeight,
      'data': data,
      'unit': unit,
    };
  }

  /// 从 JSON 字符串创建体重追踪数据
  factory WeightTrackingData.fromJsonString(String jsonString) {
    return WeightTrackingData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 创建数据副本
  WeightTrackingData copyWith({
    double? currentWeight,
    double? weightChange,
    double? targetWeight,
    List<double>? data,
    String? unit,
  }) {
    return WeightTrackingData(
      currentWeight: currentWeight ?? this.currentWeight,
      weightChange: weightChange ?? this.weightChange,
      targetWeight: targetWeight ?? this.targetWeight,
      data: data ?? this.data,
      unit: unit ?? this.unit,
    );
  }
}

/// 体重追踪卡片小组件
///
/// 一个带有动画效果的体重追踪柱状图组件，支持显示当前体重、体重变化、
/// 目标体重警戒线和历史体重数据。
///
/// 使用示例：
/// ```dart
/// WeightTrackingCard(
///   currentWeight: 89.5,
///   weightChange: -0.5,
///   targetWeight: 92.0,
///   data: [89.2, 89.8, 90.5, 91.2, 90.8, 91.5, 90.2, 89.5, 88.8, 89.3],
/// )
///
/// // 使用数据模型
/// final trackingData = WeightTrackingData(
///   currentWeight: 89.5,
///   weightChange: -0.5,
///   targetWeight: 92.0,
///   data: [89.2, 89.8, 90.5],
/// );
/// WeightTrackingCard.fromData(trackingData)
/// ```
class WeightTrackingCard extends StatefulWidget {
  /// 当前体重
  final double currentWeight;

  /// 体重变化（正值为增加，负值为减少）
  final double weightChange;

  /// 目标体重（上限警戒线）
  final double targetWeight;

  /// 历史体重数据
  final List<double> data;

  /// 体重单位，默认为 kg
  final String? unit;

  /// 卡片宽度，默认 360
  final double? width;

  /// 卡片内边距，默认 24
  final EdgeInsetsGeometry? padding;

  /// 圆角半径，默认 40
  final double? borderRadius;

  /// 图表高度，默认 128
  final double? chartHeight;

  const WeightTrackingCard({
    super.key,
    required this.currentWeight,
    required this.weightChange,
    required this.targetWeight,
    required this.data,
    this.unit,
    this.width,
    this.padding,
    this.borderRadius,
    this.chartHeight,
  });

  /// 从数据模型创建组件
  factory WeightTrackingCard.fromData(WeightTrackingData data, {
    Key? key,
    double? width,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? chartHeight,
  }) {
    return WeightTrackingCard(
      key: key,
      currentWeight: data.currentWeight,
      weightChange: data.weightChange,
      targetWeight: data.targetWeight,
      data: data.data,
      unit: data.unit,
      width: width,
      padding: padding,
      borderRadius: borderRadius,
      chartHeight: chartHeight,
    );
  }

  /// 转换为数据模型
  WeightTrackingData toData() {
    return WeightTrackingData(
      currentWeight: currentWeight,
      weightChange: weightChange,
      targetWeight: targetWeight,
      data: data,
      unit: unit,
    );
  }

  @override
  State<WeightTrackingCard> createState() => _WeightTrackingCardState();
}

class _WeightTrackingCardState extends State<WeightTrackingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
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
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: widget.width,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 40),
                border: isDark
                    ? Border.all(color: const Color(0xFF27272A))
                    : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: widget.padding ?? const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDark, theme),
                  const SizedBox(height: 40),
                  _buildChart(context, isDark, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建头部信息
  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'WEIGHT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'BMI',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: isDark ? const Color(0xFF71717A) : const Color(0xFFD4D4D8),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        _buildWeightChangeIndicator(isDark, theme),
      ],
    );
  }

  /// 构建体重变化指示器
  Widget _buildWeightChangeIndicator(bool isDark, ThemeData theme) {
    final isNegative = widget.weightChange < 0;
    final color = isNegative
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Row(
      children: [
        if (isNegative)
          Icon(
            Icons.arrow_drop_down,
            color: color,
            size: 24,
          )
        else
          Icon(
            Icons.arrow_drop_up,
            color: color,
            size: 24,
          ),
        Text(
          widget.weightChange.abs().toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  /// 构建图表
  Widget _buildChart(BuildContext context, bool isDark, ThemeData theme) {
    // 计算最小值和最大值
    final minWeight = widget.data.reduce((a, b) => a < b ? a : b);
    final maxWeight = widget.data.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;

    return SizedBox(
      height: widget.chartHeight ?? 128,
      child: Row(
        children: [
          // Y轴标签
          _buildYAxisLabels(minWeight, maxWeight, isDark, theme),
          const SizedBox(width: 40),
          // 柱状图
          Expanded(
            child: _buildBars(minWeight, range, isDark, theme),
          ),
        ],
      ),
    );
  }

  /// 构建Y轴标签
  Widget _buildYAxisLabels(double minWeight, double maxWeight, bool isDark, ThemeData theme) {
    return SizedBox(
      width: 32,
      child: Stack(
        children: [
          // 目标线标签（92）
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Text(
              widget.targetWeight.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 最小值标签（89）
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              minWeight.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建柱状图
  Widget _buildBars(double minWeight, double range, bool isDark, ThemeData theme) {
    return Stack(
      children: [
        // 警戒线
        _buildTargetLine(minWeight, range, theme),
        // 数据柱
        _buildDataBars(minWeight, range, isDark, theme),
      ],
    );
  }

  /// 构建目标线（警戒线）
  Widget _buildTargetLine(double minWeight, double range, ThemeData theme) {
    final targetRatio = (widget.targetWeight - minWeight) / range;
    final chartHeight = widget.chartHeight ?? 128;
    final topPosition = (1 - targetRatio) * chartHeight;

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.error.withOpacity(0.6),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建数据柱
  Widget _buildDataBars(double minWeight, double range, bool isDark, ThemeData theme) {
    final barWidth = 4.0;
    final chartHeight = widget.chartHeight ?? 128;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.data.length, (index) {
          final value = widget.data[index];
          final normalizedValue = (value - minWeight) / range;
          final barHeight = normalizedValue * chartHeight * 0.6; // 60% of chart height
          final isCurrentDay = index == widget.data.length - 1;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = 0.3 + (index / widget.data.length) * 0.7;
              final animationValue = (_animationController.value - delay).clamp(0.0, 1.0) / (1 - delay);

              return Container(
                width: barWidth,
                height: chartHeight,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 当前日标记
                    if (isCurrentDay)
                      Container(
                        width: barWidth,
                        height: chartHeight * 0.06 * animationValue, // 小红条
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    // 数据柱
                    Container(
                      width: barWidth,
                      height: barHeight * animationValue,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
