import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 支出对比图表卡片
///
/// 用于展示支出对比的卡片组件，支持：
/// - 本月支出金额显示（带动画计数）
/// - 变化百分比徽章
/// - 双数据系列柱状图（上月 vs 本月）
/// - 深色/浅色主题适配
class ExpenseComparisonChartCardWidget extends StatefulWidget {
  /// 标题文本
  final String title;

  /// 本月金额
  final double currentAmount;

  /// 单位
  final String unit;

  /// 变化百分比
  final double changePercent;

  /// 日数据列表
  final List<DailyExpenseDataModel> dailyData;

  /// Y轴最大值
  final double maxValue;

  /// X轴标签列表（自定义图例）
  final List<String> labels;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const ExpenseComparisonChartCardWidget({
    super.key,
    required this.title,
    required this.currentAmount,
    required this.unit,
    required this.changePercent,
    required this.dailyData,
    this.maxValue = 24.0,
    this.labels = const [],
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于小组件系统）
  factory ExpenseComparisonChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final dailyDataList = (props['dailyData'] as List<dynamic>?);
    final dailyData =
        dailyDataList?.map((item) {
          final map = item as Map<String, dynamic>;
          return DailyExpenseDataModel(
            lastMonth: (map['lastMonth'] as num).toDouble(),
            currentMonth: (map['currentMonth'] as num).toDouble(),
          );
        }).toList() ??
        [];

    final labelsList =
        (props['labels'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return ExpenseComparisonChartCardWidget(
      title: props['title'] as String? ?? '本月支出',
      currentAmount: (props['currentAmount'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      changePercent: (props['changePercent'] as num?)?.toDouble() ?? 0.0,
      dailyData: dailyData,
      maxValue: (props['maxValue'] as num?)?.toDouble() ?? 24.0,
      labels: labelsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ExpenseComparisonChartCardWidget> createState() =>
      _ExpenseComparisonChartCardWidgetState();
}

class _ExpenseComparisonChartCardWidgetState
    extends State<ExpenseComparisonChartCardWidget>
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

  /// 构建图例行
  Widget _buildLegendRow(bool isDark, Color primaryColor) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: widget.size.getLegendIndicatorWidth(),
              height: widget.size.getLegendIndicatorHeight(),
              margin: EdgeInsets.only(right: widget.size.getSmallSpacing()),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF475569) : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '上月',
              style: TextStyle(
                fontSize: widget.size.getLegendFontSize() * 0.8,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        SizedBox(width: widget.size.getItemSpacing()),
        Row(
          children: [
            Container(
              width: widget.size.getLegendIndicatorWidth(),
              height: widget.size.getLegendIndicatorHeight(),
              margin: EdgeInsets.only(right: widget.size.getSmallSpacing()),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '本月',
              style: TextStyle(
                fontSize: widget.size.getLegendFontSize(),
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建变化百分比徽章
  Widget _buildChangePercentBadge(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.size.getSmallSpacing() * 2,
        vertical: widget.size.getSmallSpacing() / 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33EF4444) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.785, // -45度
            child: Icon(
              Icons.arrow_forward,
              size: widget.size.getSubtitleFontSize(),
              color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
            ),
          ),
          SizedBox(width: widget.size.getItemSpacing() / 4),
          Text(
            '+${widget.changePercent}%',
            style: TextStyle(
              fontSize: widget.size.getSubtitleFontSize(),
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 400,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和金额
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: widget.size.getTitleFontSize(),
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: widget.size.getItemSpacing() * 0.5),
                          SizedBox(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedFlipCounter(
                                  value:
                                      widget.currentAmount * _animation.value,
                                  fractionDigits: 2,
                                  textStyle: TextStyle(
                                    fontSize:
                                        widget.size.getLargeFontSize() * 0.6,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(
                                  width: widget.size.getItemSpacing() / 2,
                                ),
                                Text(
                                  widget.unit,
                                  style: TextStyle(
                                    fontSize: widget.size.getSubtitleFontSize(),
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF6B7280),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Wide size: 图例和变化百分比在右侧
                      if (widget.size is WideSize ||
                          widget.size is Wide2Size ||
                          widget.size is Wide3Size)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildLegendRow(isDark, primaryColor),
                            SizedBox(height: widget.size.getItemSpacing()),
                            _buildChangePercentBadge(isDark),
                          ],
                        ),
                    ],
                  ),
                  // 非 wide size: 图例和变化百分比在新的一行横向展示
                  if (!(widget.size is WideSize ||
                      widget.size is Wide2Size ||
                      widget.size is Wide3Size)) ...[
                    SizedBox(height: widget.size.getItemSpacing()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLegendRow(isDark, primaryColor),
                        _buildChangePercentBadge(isDark),
                      ],
                    ),
                  ],
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 柱状图
                  Flexible(
                    child: _BarChartWidget(
                      data: widget.dailyData,
                      maxValue: widget.maxValue,
                      labels: widget.labels,
                      animation: _animation,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      size: widget.size,
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

/// 日支出数据模型
class DailyExpenseDataModel {
  final double lastMonth;
  final double currentMonth;

  const DailyExpenseDataModel({
    required this.lastMonth,
    required this.currentMonth,
  });

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {'lastMonth': lastMonth, 'currentMonth': currentMonth};
  }

  /// 从 Map 创建
  factory DailyExpenseDataModel.fromMap(Map<String, dynamic> map) {
    return DailyExpenseDataModel(
      lastMonth: (map['lastMonth'] as num).toDouble(),
      currentMonth: (map['currentMonth'] as num).toDouble(),
    );
  }
}

/// 柱状图组件
class _BarChartWidget extends StatelessWidget {
  final List<DailyExpenseDataModel> data;
  final double maxValue;
  final List<String> labels;
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;
  final HomeWidgetSize size;

  /// 柱子最小宽度
  static const double minBarWidth = 10.0;

  /// 柱子间距
  static const double barSpacing = 4.0;

  const _BarChartWidget({
    required this.data,
    required this.maxValue,
    required this.labels,
    required this.animation,
    required this.isDark,
    required this.primaryColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 计算总宽度：每个柱子的宽度 + 间距
    final barWidth = size.getBarWidth().clamp(minBarWidth, double.infinity);
    final stepWidth = barWidth + barSpacing * 2;
    final totalWidth = data.length * stepWidth;
    final labelHeight = size.getLegendFontSize() * 2;

    // 整个图表区域（柱状图 + X轴标签）使用同一个滚动控制器
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            // 柱状图主体
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(data.length, (index) {
                  final barAnimation = CurvedAnimation(
                    parent: animation,
                    curve: Interval(
                      index * 0.015,
                      0.5 + index * 0.015,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: barSpacing),
                    child: _BarItemWidget(
                      lastMonth: data[index].lastMonth,
                      currentMonth: data[index].currentMonth,
                      maxValue: maxValue,
                      animation: barAnimation,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      size: size,
                      minWidth: minBarWidth,
                    ),
                  );
                }),
              ),
            ),
            // X轴标签 - 使用自绘，与柱状图在同一滚动容器中
            SizedBox(height: size.getSmallSpacing() * 3),
            CustomPaint(
              size: Size(totalWidth, labelHeight),
              painter: _XAxisLabelPainter(
                labels:
                    labels.isEmpty
                        ? ['01', '05', '10', '15', '20', '25', '30']
                        : labels,
                labelIndices:
                    labels.isEmpty
                        ? [0, 4, 9, 14, 19, 24, 29]
                        : List.generate(labels.length, (i) => i),
                totalDataCount: data.length,
                fontSize: size.getLegendFontSize(),
                color:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                barWidth: barWidth,
                barSpacing: barSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// X轴标签绘制器
class _XAxisLabelPainter extends CustomPainter {
  final List<String> labels;
  final List<int> labelIndices;
  final int totalDataCount;
  final double fontSize;
  final Color color;
  final double barWidth;
  final double barSpacing;

  _XAxisLabelPainter({
    required this.labels,
    required this.labelIndices,
    required this.totalDataCount,
    required this.fontSize,
    required this.color,
    required this.barWidth,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final stepWidth = barWidth + barSpacing * 2;

    for (int i = 0; i < labels.length; i++) {
      final labelIndex = labelIndices[i];
      if (labelIndex >= totalDataCount) continue;

      final x = labelIndex * stepWidth + stepWidth / 2;

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: 0.5,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _XAxisLabelPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.totalDataCount != totalDataCount ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.color != color ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpacing != barSpacing;
  }
}

/// 单个柱状图项
class _BarItemWidget extends StatelessWidget {
  final double lastMonth;
  final double currentMonth;
  final double maxValue;
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;
  final HomeWidgetSize size;
  final double minWidth;

  const _BarItemWidget({
    required this.lastMonth,
    required this.currentMonth,
    required this.maxValue,
    required this.animation,
    required this.isDark,
    required this.primaryColor,
    required this.size,
    this.minWidth = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    // 使用最小宽度限制
    final barWidth = size.getBarWidth().clamp(minWidth, double.infinity);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final lastMonthHeight =
                maxValue > 0
                    ? (lastMonth / maxValue * availableHeight * animation.value)
                    : 0.0;
            final currentMonthHeight =
                maxValue > 0
                    ? (currentMonth /
                        maxValue *
                        availableHeight *
                        animation.value)
                    : 0.0;

            return SizedBox(
              width: barWidth,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: barWidth,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // 上月柱（背景）
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: barWidth,
                          height: lastMonthHeight,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFDBEAFE),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      // 本月柱（前景）
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: barWidth,
                          height: currentMonthHeight,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
