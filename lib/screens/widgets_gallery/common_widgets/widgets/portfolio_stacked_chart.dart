import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 资产类型数据模型
class AssetType {
  final String label;
  final Color color;

  const AssetType({required this.label, required this.color});

  /// 从 JSON 创建
  factory AssetType.fromJson(Map<String, dynamic> json) {
    return AssetType(
      label: json['label'] as String? ?? '',
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'label': label, 'color': color.value};
  }
}

/// 月度数据模型
class MonthlyData {
  final int stocks;
  final int funds;
  final int bonds;

  const MonthlyData({
    required this.stocks,
    required this.funds,
    required this.bonds,
  });

  /// 从 JSON 创建
  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      stocks: json['stocks'] as int? ?? 0,
      funds: json['funds'] as int? ?? 0,
      bonds: json['bonds'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'stocks': stocks, 'funds': funds, 'bonds': bonds};
  }
}

/// 投资组合堆叠图小组件
class PortfolioStackedChartWidget extends StatefulWidget {
  final String title;
  final double totalAmount;
  final double growthPercentage;
  final List<AssetType> assetTypes;
  final List<MonthlyData> monthlyData;
  final List<String> monthLabels;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const PortfolioStackedChartWidget({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.growthPercentage,
    required this.assetTypes,
    required this.monthlyData,
    required this.monthLabels,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory PortfolioStackedChartWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final assetTypesList =
        (props['assetTypes'] as List<dynamic>?)
            ?.map((e) => AssetType.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final monthlyDataList =
        (props['monthlyData'] as List<dynamic>?)
            ?.map((e) => MonthlyData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final monthLabelsList =
        (props['monthLabels'] as List<dynamic>?)?.cast<String>() ?? const [];

    return PortfolioStackedChartWidget(
      title: props['title'] as String? ?? '',
      totalAmount: (props['totalAmount'] as num?)?.toDouble() ?? 0.0,
      growthPercentage: (props['growthPercentage'] as num?)?.toDouble() ?? 0.0,
      assetTypes: assetTypesList,
      monthlyData: monthlyDataList,
      monthLabels: monthLabelsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<PortfolioStackedChartWidget> createState() =>
      _PortfolioStackedChartWidgetState();
}

class _PortfolioStackedChartWidgetState
    extends State<PortfolioStackedChartWidget>
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
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: widget.size.getLegendFontSize(),
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                        ),
                      ),
                      SizedBox(height: widget.size.getItemSpacing()),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedFlipCounter(
                                value: widget.totalAmount * _animation.value,
                                fractionDigits: 2,
                                prefix: '\$',
                                duration: const Duration(milliseconds: 1000),
                                textStyle: TextStyle(
                                  fontSize: widget.size.getLargeFontSize() * 0.38,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : Colors.grey.shade900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: widget.size.getItemSpacing()),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.size.getSmallSpacing(),
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.green.shade900.withOpacity(0.3)
                                      : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(
                                widget.size.getLegendIndicatorWidth() / 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: widget.size.getIconSize() * 0.5,
                                  color:
                                      isDark
                                          ? Colors.green.shade400
                                          : Colors.green.shade600,
                                ),
                                SizedBox(
                                  width: widget.size.getSmallSpacing(),
                                ),
                                Text(
                                  '+${widget.growthPercentage.toInt()}%',
                                  style: TextStyle(
                                    fontSize: widget.size.getLegendFontSize() - 1,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark
                                            ? Colors.green.shade400
                                            : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: widget.size.getItemSpacing()),
                      Wrap(
                        spacing: widget.size.getItemSpacing() * 1.5,
                        children:
                            widget.assetTypes.map((type) {
                              final color =
                                  type.label == 'Bonds' && isDark
                                      ? const Color(0xFFE5E7EB)
                                      : type.color;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: widget.size.getLegendIndicatorWidth() * 0.5,
                                    height: widget.size.getLegendIndicatorHeight() * 0.5,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(
                                    width: widget.size.getSmallSpacing(),
                                  ),
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      fontSize: widget.size.getLegendFontSize(),
                                      fontWeight: FontWeight.w400,
                                      color:
                                          isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _StackedBarChart(
                    monthlyData: widget.monthlyData,
                    assetTypes: widget.assetTypes,
                    animation: _animation,
                    isDark: isDark,
                    size: widget.size,
                  ),
                  SizedBox(height: widget.size.getItemSpacing()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        widget.monthLabels.map((label) {
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: widget.size.getLegendFontSize(),
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                            ),
                          );
                        }).toList(),
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

class _StackedBarChart extends StatelessWidget {
  final List<MonthlyData> monthlyData;
  final List<AssetType> assetTypes;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _StackedBarChart({
    required this.monthlyData,
    required this.assetTypes,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final maxTotal = monthlyData
        .map((d) => d.stocks + d.funds + d.bonds)
        .reduce((a, b) => a > b ? a : b);

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(monthlyData.length, (index) {
          final data = monthlyData[index];
          final barAnimation = CurvedAnimation(
            parent: animation,
            curve: Interval(
              index * 0.05,
              0.5 + index * 0.03,
              curve: Curves.easeOutCubic,
            ),
          );

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.getBarSpacing(),
              ),
              child: _StackedBar(
                data: data,
                animation: barAnimation,
                isDark: isDark,
                maxTotal: maxTotal,
                size: size,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  final MonthlyData data;
  final Animation<double> animation;
  final bool isDark;
  final int maxTotal;
  final HomeWidgetSize size;

  const _StackedBar({
    required this.data,
    required this.animation,
    required this.isDark,
    required this.maxTotal,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final borderRadius = size.getSmallSpacing();

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final stocksHeight =
                (data.stocks / maxTotal) * availableHeight * animation.value;
            final fundsHeight =
                (data.funds / maxTotal) * availableHeight * animation.value;
            final bondsHeight =
                (data.bonds / maxTotal) * availableHeight * animation.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: bondsHeight,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF000000),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                Container(
                  height: fundsHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                Container(
                  height: stocksHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94B8FF),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
