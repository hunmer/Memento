import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 投资组合堆叠图示例
class PortfolioStackedChartExample extends StatelessWidget {
  const PortfolioStackedChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('投资组合堆叠图')),
      body: Container(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF3F4F6),
        child: const Center(
          child: PortfolioStackedChartWidget(
            title: 'Overview',
            totalAmount: 231471.24,
            growthPercentage: 12,
            assetTypes: [
              AssetType(label: 'Stocks', color: Color(0xFF94B8FF)),
              AssetType(label: 'Funds', color: Color(0xFF2563EB)),
              AssetType(label: 'Bonds', color: Color(0xFF000000)),
            ],
            monthlyData: [
              MonthlyData(stocks: 48, funds: 32, bonds: 32),
              MonthlyData(stocks: 40, funds: 28, bonds: 36),
              MonthlyData(stocks: 32, funds: 24, bonds: 32),
              MonthlyData(stocks: 24, funds: 20, bonds: 28),
              MonthlyData(stocks: 16, funds: 20, bonds: 24),
              MonthlyData(stocks: 12, funds: 36, bonds: 28),
              MonthlyData(stocks: 24, funds: 8, bonds: 28),
              MonthlyData(stocks: 20, funds: 8, bonds: 32),
              MonthlyData(stocks: 16, funds: 6, bonds: 24),
              MonthlyData(stocks: 12, funds: 8, bonds: 28),
              MonthlyData(stocks: 8, funds: 4, bonds: 24),
              MonthlyData(stocks: 16, funds: 12, bonds: 24),
              MonthlyData(stocks: 32, funds: 16, bonds: 28),
              MonthlyData(stocks: 20, funds: 20, bonds: 24),
              MonthlyData(stocks: 24, funds: 8, bonds: 24),
            ],
            monthLabels: ['May', 'Jul', 'Oct'],
          ),
        ),
      ),
    );
  }
}

/// 资产类型数据模型
class AssetType {
  final String label;
  final Color color;

  const AssetType({
    required this.label,
    required this.color,
  });
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
}

/// 投资组合堆叠图小组件
class PortfolioStackedChartWidget extends StatefulWidget {
  final String title;
  final double totalAmount;
  final double growthPercentage;
  final List<AssetType> assetTypes;
  final List<MonthlyData> monthlyData;
  final List<String> monthLabels;

  const PortfolioStackedChartWidget({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.growthPercentage,
    required this.assetTypes,
    required this.monthlyData,
    required this.monthLabels,
  });

  @override
  State<PortfolioStackedChartWidget> createState() => _PortfolioStackedChartWidgetState();
}

class _PortfolioStackedChartWidgetState extends State<PortfolioStackedChartWidget>
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
              width: 250,
              height: 250,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                borderRadius: BorderRadius.circular(40),
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
                  // 顶部信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: AnimatedFlipCounter(
                              value: widget.totalAmount * _animation.value,
                              fractionDigits: 2,
                              prefix: '\$',
                              duration: const Duration(milliseconds: 1000),
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.grey.shade900,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.green.shade900.withOpacity(0.3)
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 12,
                                  color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '+${widget.growthPercentage.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 资产类型图例
                      Wrap(
                        spacing: 12,
                        children: widget.assetTypes.map((type) {
                          final color = type.label == 'Bonds' && isDark
                              ? const Color(0xFFE5E7EB)
                              : type.color;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 堆叠柱状图
                  _StackedBarChart(
                    monthlyData: widget.monthlyData,
                    assetTypes: widget.assetTypes,
                    animation: _animation,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  // 月份标签
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widget.monthLabels.map((label) {
                      return Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
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

/// 堆叠柱状图组件
class _StackedBarChart extends StatelessWidget {
  final List<MonthlyData> monthlyData;
  final List<AssetType> assetTypes;
  final Animation<double> animation;
  final bool isDark;

  const _StackedBarChart({
    required this.monthlyData,
    required this.assetTypes,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 计算所有数据中的最大总和，用于归一化高度
    final maxTotal = monthlyData
        .map((d) => d.stocks + d.funds + d.bonds)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 96,
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
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _StackedBar(
                data: data,
                animation: barAnimation,
                isDark: isDark,
                maxTotal: maxTotal,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 单个堆叠柱
class _StackedBar extends StatelessWidget {
  final MonthlyData data;
  final Animation<double> animation;
  final bool isDark;
  final int maxTotal;

  const _StackedBar({
    required this.data,
    required this.animation,
    required this.isDark,
    required this.maxTotal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 根据最大总和和可用高度(96)计算每部分的高度
        final stocksHeight = (data.stocks / maxTotal) * 96 * animation.value;
        final fundsHeight = (data.funds / maxTotal) * 96 * animation.value;
        final bondsHeight = (data.bonds / maxTotal) * 96 * animation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Bonds (底部)
            Container(
              height: bondsHeight,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF000000),
            ),
            // Funds (中间)
            Container(
              height: fundsHeight,
              color: const Color(0xFF2563EB),
            ),
            // Stocks (顶部)
            Container(
              height: stocksHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF94B8FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
