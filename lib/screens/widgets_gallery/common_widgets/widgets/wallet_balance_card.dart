import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 钱包余额概览卡片小组件
///
/// 显示钱包余额、可用余额、收入支出统计和操作按钮
class WalletBalanceCardWidget extends StatefulWidget {
  /// 头像 URL
  final String avatarUrl;

  /// 可用余额
  final double availableBalance;

  /// 总余额
  final double totalBalance;

  /// 变化百分比
  final int changePercent;

  /// 收入
  final double income;

  /// 支出
  final double expenses;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const WalletBalanceCardWidget({
    super.key,
    required this.avatarUrl,
    required this.availableBalance,
    required this.totalBalance,
    required this.changePercent,
    required this.income,
    required this.expenses,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从属性 Map 创建组件（用于公共小组件系统）
  static WalletBalanceCardWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return WalletBalanceCardWidget(
      avatarUrl: props['avatarUrl'] as String? ?? '',
      availableBalance: (props['availableBalance'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (props['totalBalance'] as num?)?.toDouble() ?? 0.0,
      changePercent: props['changePercent'] as int? ?? 0,
      income: (props['income'] as num?)?.toDouble() ?? 0.0,
      expenses: (props['expenses'] as num?)?.toDouble() ?? 0.0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<WalletBalanceCardWidget> createState() =>
      _WalletBalanceCardWidgetState();
}

class _WalletBalanceCardWidgetState extends State<WalletBalanceCardWidget>
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
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryColor = const Color(0xFF18181B);
    final btnSecondaryColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6);

    // 计算进度比例
    final progress = widget.availableBalance / widget.totalBalance;

    return Container(
      width: widget.inline ? double.maxFinite : 340,
      padding: widget.size.getPadding(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像和余额信息
          Row(
            children: [
              ClipOval(
                child: Image.network(
                  widget.avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person),
                    );
                  },
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${widget.availableBalance.toStringAsFixed(2)} Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: widget.size.getItemSpacing() / 2),
                    Row(
                      children: [
                        AnimatedFlipCounter(
                          value: widget.totalBalance * _animation.value,
                          fractionDigits: 2,
                          prefix: '\$',
                          textStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(width: widget.size.getItemSpacing()),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.green.shade900.withOpacity(0.4)
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${widget.changePercent}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.green.shade400
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: widget.size.getTitleSpacing()),

          // 进度条
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress * _animation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (progress * 300) - 10,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade200 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: widget.size.getItemSpacing()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatLabel(isDark, 'Income:', '\$${widget.income}'),
                  _buildStatLabel(isDark, 'Expenses:', '\$${widget.expenses}'),
                ],
              ),
            ],
          ),
          SizedBox(height: widget.size.getTitleSpacing()),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  isDark,
                  'Send',
                  primaryColor,
                  Colors.white,
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Expanded(
                child: _buildActionButton(
                  isDark,
                  'Receive',
                  btnSecondaryColor,
                  isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              _buildAddButton(isDark, btnSecondaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(bool isDark, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        SizedBox(width: widget.size.getItemSpacing() / 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    bool isDark,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark, Color bgColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add,
        color: isDark ? Colors.white : Colors.grey.shade900,
        size: 24,
      ),
    );
  }
}
