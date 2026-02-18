import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 余额卡片数据模型
///
/// 用于余额卡片的数据序列化
class BalanceCardData {
  /// 卡片标题
  final String title;

  /// 当前余额
  final double balance;

  /// 可用额度
  final double available;

  /// 每周数据 (7天，0.0-1.0)
  final List<double> weeklyData;

  const BalanceCardData({
    required this.title,
    required this.balance,
    required this.available,
    required this.weeklyData,
  });

  /// 从 JSON 创建
  factory BalanceCardData.fromJson(Map<String, dynamic> json) {
    return BalanceCardData(
      title: json['title'] as String,
      balance: (json['balance'] as num).toDouble(),
      available: (json['available'] as num).toDouble(),
      weeklyData:
          (json['weeklyData'] as List<dynamic>)
              .map((e) => (e as num).toDouble())
              .toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'balance': balance,
      'available': available,
      'weeklyData': weeklyData,
    };
  }

  /// 创建副本
  BalanceCardData copyWith({
    String? title,
    double? balance,
    double? available,
    List<double>? weeklyData,
  }) {
    return BalanceCardData(
      title: title ?? this.title,
      balance: balance ?? this.balance,
      available: available ?? this.available,
      weeklyData: weeklyData ?? this.weeklyData,
    );
  }
}

/// 余额卡片小组件
///
/// 展示账户余额和可用额度，带有每周数据柱状图
class ModernRoundedBalanceCard extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 当前余额
  final double balance;

  /// 可用额度
  final double available;

  /// 每周数据 (7天，0.0-1.0)
  final List<double> weeklyData;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ModernRoundedBalanceCard({
    super.key,
    required this.title,
    required this.balance,
    required this.available,
    required this.weeklyData,
    this.size = const MediumSize(),
  });

  /// 从数据模型创建
  factory ModernRoundedBalanceCard.fromData(
    BalanceCardData data, {
    HomeWidgetSize size = const MediumSize(),
  }) {
    return ModernRoundedBalanceCard(
      title: data.title,
      balance: data.balance,
      available: data.available,
      weeklyData: data.weeklyData,
      size: size,
    );
  }

  /// 从 props 创建实例（用于公共小组件系统）
  factory ModernRoundedBalanceCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final weeklyDataList = props['weeklyData'] as List?;
    final weeklyData =
        weeklyDataList?.map((e) => (e as num).toDouble()).toList() ??
        <double>[];

    return ModernRoundedBalanceCard(
      title: props['title'] as String? ?? '余额',
      balance: (props['balance'] as num?)?.toDouble() ?? 0.0,
      available: (props['available'] as num?)?.toDouble() ?? 0.0,
      weeklyData: weeklyData,
      size: size,
    );
  }

  @override
  State<ModernRoundedBalanceCard> createState() =>
      _ModernRoundedBalanceCardState();
}

class _ModernRoundedBalanceCardState extends State<ModernRoundedBalanceCard>
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
    final backgroundColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final secondaryTextColor =
        isDark ? const Color(0xFFAEAEB2) : const Color(0xFF8E8E93);
    final barBgColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEFEFF4);

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // 根据 size 计算尺寸
    final padding = widget.size.getPadding();
    final titleFontSize = widget.size.getTitleFontSize();
    final valueFontSize = widget.size.getLargeFontSize() * 0.35; // 约 13-20px
    final subtitleFontSize = widget.size.getSubtitleFontSize();
    final smallSpacing = widget.size.getSmallSpacing();
    final titleSpacing = widget.size.getTitleSpacing();
    final barWidth = widget.size.getBarWidth();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: padding,
              constraints: widget.size.getHeightConstraints(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和余额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: titleFontSize * 0.45, // 约 7-13px
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: smallSpacing * 2),
                      SizedBox(
                        height: valueFontSize * 1.2,
                        child: AnimatedFlipCounter(
                          value: widget.balance * _animation.value,
                          prefix: '\$',
                          fractionDigits: 2,
                          thousandSeparator: ',',
                          textStyle: TextStyle(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: smallSpacing),
                      Text(
                        '\$${widget.available.toStringAsFixed(2)} Available',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: titleSpacing * 0.8),

                  // 每周柱状图 - 支持横向滚动
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;
                        final labelHeight =
                            widget.size.getLegendFontSize() * 1.2 +
                            smallSpacing * 3;
                        final barHeight = (availableHeight - labelHeight).clamp(
                          0.0,
                          availableHeight,
                        );

                        return Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: smallSpacing,
                            ),
                            child: SizedBox(
                              height: barHeight + labelHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  widget.weeklyData.length,
                                  (index) {
                                  final value = widget.weeklyData[index];
                                  // 计算动画区间，确保 end 不超过 1.0
                                  final totalItems = widget.weeklyData.length;
                                  final animationStart =
                                      index / totalItems * 0.5;
                                  final animationEnd =
                                      (index + 1) / totalItems * 0.9;
                                  final itemAnimation = CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      animationStart.clamp(0.0, 1.0),
                                      animationEnd.clamp(0.0, 1.0),
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          index < widget.weeklyData.length - 1
                                              ? barWidth * 0.5
                                              : 0,
                                    ),
                                    child: _WeeklyBar(
                                      label: weekDays[index % weekDays.length],
                                      value: value * itemAnimation.value,
                                      backgroundColor: barBgColor,
                                      size: widget.size,
                                      barWidth: barWidth,
                                      barHeight: barHeight,
                                    ),
                                  );
                                },
                              ),
                            ),
                            ),
                          ),
                        );
                      },
                    ),
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

/// 每周柱状条
class _WeeklyBar extends StatelessWidget {
  final String label;
  final double value;
  final Color backgroundColor;
  final HomeWidgetSize size;
  final double barWidth;
  final double barHeight;

  const _WeeklyBar({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.size,
    required this.barWidth,
    required this.barHeight,
  });

  // 渐变色配置
  List<Color> get _gradients {
    // 根据数值大小生成不同的渐变
    if (value > 0.8) {
      return [
        const Color(0xFFFB923C),
        const Color(0xFF3B82F6),
      ]; // orange -> blue
    } else if (value > 0.6) {
      return [
        const Color(0xFFEF4444),
        const Color(0xFF8B5CF6),
      ]; // red -> purple
    } else if (value > 0.4) {
      return [
        const Color(0xFFFACC15),
        const Color(0xFF3B82F6),
      ]; // yellow -> blue
    } else {
      return [
        const Color(0xFFEF4444),
        const Color(0xFFA78BFA),
      ]; // red -> purple
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据 size 计算尺寸
    final legendFontSize = size.getLegendFontSize();
    final smallSpacing = size.getSmallSpacing();

    // 圆角为 barWidth 的一半
    final borderRadius = barWidth / 2;

    // 填充高度基于 barHeight
    final filledHeight = barHeight * value.clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: barWidth,
              height: filledHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: _gradients,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(borderRadius),
                  bottomRight: Radius.circular(borderRadius),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: smallSpacing * 3),
        SizedBox(
          height: legendFontSize * 1.2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: legendFontSize,
              fontWeight: FontWeight.w500,
              color:
                  backgroundColor == const Color(0xFF3A3A3C)
                      ? const Color(0xFFAEAEB2)
                      : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }
}
