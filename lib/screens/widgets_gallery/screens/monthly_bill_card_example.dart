import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 月度账单卡片示例
class MonthlyBillCardExample extends StatelessWidget {
  const MonthlyBillCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('月度账单卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MonthlyBillCardWidget(
            title: '6月账单',
            income: 1024.00,
            expense: 2048.00,
            balance: -1024.00,
          ),
        ),
      ),
    );
  }
}

/// 月度账单统计小组件
class MonthlyBillCardWidget extends StatefulWidget {
  /// 账单标题
  final String title;

  /// 收入金额
  final double income;

  /// 支出金额
  final double expense;

  /// 结余金额
  final double balance;

  const MonthlyBillCardWidget({
    super.key,
    required this.title,
    required this.income,
    required this.expense,
    required this.balance,
  });

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
    final titleColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final dividerColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    // 使用主题颜色而非硬编码
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
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
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
                  // 标题
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 收入
                  _BillItemWidget(
                    label: '收入',
                    value: widget.income,
                    valueColor: incomeColor,
                    showPlus: true,
                    animation: _fadeInAnimation,
                    index: 0,
                  ),
                  const SizedBox(height: 16),

                  // 支出
                  _BillItemWidget(
                    label: '支出',
                    value: widget.expense,
                    valueColor: expenseColor,
                    showPlus: false,
                    animation: _fadeInAnimation,
                    index: 1,
                  ),
                  const SizedBox(height: 20),

                  // 分隔线
                  Container(
                    height: 1,
                    color: dividerColor,
                  ),
                  const SizedBox(height: 20),

                  // 结余
                  _BillItemWidget(
                    label: '结余',
                    value: widget.balance,
                    valueColor: incomeColor,
                    showPlus: true,
                    isLarge: true,
                    animation: _fadeInAnimation,
                    index: 2,
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

  const _BillItemWidget({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.showPlus,
    this.isLarge = false,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    // 计算延迟动画
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.12,
        0.5 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    final fontSize = isLarge ? 28.0 : 18.0;
    final labelFontSize = isLarge ? 14.0 : 14.0;
    final counterHeight = fontSize * 1.1;
    final rowHeight = counterHeight + 4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.normal,
            color: labelColor,
          ),
        ),
        SizedBox(
          height: rowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showPlus && value >= 0)
                SizedBox(
                  height: fontSize * 0.8,
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: valueColor,
                      fontSize: fontSize * 0.8,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
              SizedBox(
                width: isLarge ? 140 : 100,
                height: counterHeight,
                child: AnimatedFlipCounter(
                  value: value.abs() * itemAnimation.value,
                  fractionDigits: 2,
                  textStyle: TextStyle(
                    color: valueColor,
                    fontSize: fontSize,
                    fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
                    fontFamily: 'monospace',
                    height: 1.0,
                    letterSpacing: isLarge ? -1.0 : -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
