import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/monthly_bill_card_data.dart';

/// 月度账单统计小组件
///
/// 用于显示月度账单信息，包括收入、支出和结余
/// 支持正负金额显示，负余额用红色标记
/// 包含入场动画效果和数字翻转动画
class MonthlyBillCardWidget extends StatefulWidget {
  /// 账单数据
  final MonthlyBillCardData data;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const MonthlyBillCardWidget({
    super.key,
    required this.data,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MonthlyBillCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final dataString = props['data'] as String?;
    final data =
        dataString != null && dataString.isNotEmpty
            ? MonthlyBillCardData.fromJsonString(dataString)
            : MonthlyBillCardData.defaults();

    return MonthlyBillCardWidget(
      data: data,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<MonthlyBillCardWidget> createState() => _MonthlyBillCardWidgetState();
}

class _MonthlyBillCardWidgetState extends State<MonthlyBillCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
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

    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final dividerColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    // 使用主题颜色
    final incomeColor = Theme.of(context).colorScheme.primary;
    final expenseColor = Theme.of(context).colorScheme.error;

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : null,
              height: widget.inline ? double.maxFinite : null,
              constraints:
                  widget.inline ? null : widget.size.getHeightConstraints(),
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部：标题
                  Text(
                    widget.data.title,
                    style: TextStyle(
                      fontSize: widget.size.getTitleFontSize() * 0.8,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 中间：收入和支出
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 收入
                      _BillItemWidget(
                        label: '收入',
                        value: widget.data.income,
                        valueColor: incomeColor,
                        showPlus: true,
                        animation: _fadeInAnimation,
                        index: 0,
                        size: widget.size,
                      ),
                      SizedBox(height: widget.size.getItemSpacing()),

                      // 支出
                      _BillItemWidget(
                        label: '支出',
                        value: widget.data.expense,
                        valueColor: expenseColor,
                        showPlus: false,
                        animation: _fadeInAnimation,
                        index: 1,
                        size: widget.size,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 底部：分隔线和结余
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 分隔线
                      Container(height: 1, color: dividerColor),
                      SizedBox(
                        height:
                            widget.size is SmallSize
                                ? 0
                                : widget.size.getTitleSpacing(),
                      ),

                      // 结余
                      _BillItemWidget(
                        label: '结余',
                        value: widget.data.balance,
                        valueColor: incomeColor,
                        showPlus: true,
                        isLarge: true,
                        animation: _fadeInAnimation,
                        index: 2,
                        size: widget.size,
                      ),
                    ],
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

/// 账单列表项组件
class _BillItemWidget extends StatelessWidget {
  final String label;
  final double value;
  final Color valueColor;
  final bool showPlus;
  final bool isLarge;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _BillItemWidget({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.showPlus,
    this.isLarge = false,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    // 计算延迟动画
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.12,
        0.5 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    // 根据 size 计算字体大小
    final fontSize =
        isLarge
            ? size.getTitleFontSize() *
                1.0 // 约 16-28px
            : size.getSubtitleFontSize() * 1.2; // 约 17-19px
    final labelFontSize = size.getSubtitleFontSize(); // 约 12-16px
    final counterHeight = fontSize * 1.1;
    final rowHeight = counterHeight + size.getSmallSpacing();

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.normal,
            color: labelColor,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: rowHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showPlus && value >= 0)
                Text(
                  '+',
                  style: TextStyle(
                    color: valueColor,
                    fontSize: fontSize * 0.8,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              AnimatedFlipCounter(
                value: value.abs() * itemAnimation.value,
                fractionDigits: 2,
                prefix: '',
                textStyle: TextStyle(
                  color: valueColor,
                  fontSize: fontSize,
                  fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'monospace',
                  height: 1.0,
                  letterSpacing: isLarge ? -1.0 : -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
