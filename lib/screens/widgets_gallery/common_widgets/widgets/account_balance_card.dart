import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/account_balance_card_data.dart';

/// 账户余额卡片小组件
///
/// 用于显示多个账户的余额信息，包括账户名称、图标、账单数量和余额
/// 支持正负余额显示，负余额用红色标记
/// 包含入场动画效果
class AccountBalanceCardWidget extends StatefulWidget {
  /// 账户列表
  final List<AccountBalanceCardData> accounts;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const AccountBalanceCardWidget({
    super.key,
    required this.accounts,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory AccountBalanceCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final accountsList = props['accounts'] as String?;
    final accounts = accountsList != null && accountsList.isNotEmpty
        ? AccountBalanceCardData.listFromJson(accountsList)
        : _getDefaultAccounts();

    return AccountBalanceCardWidget(
      accounts: accounts,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  /// 获取默认账户数据
  static List<AccountBalanceCardData> _getDefaultAccounts() {
    return [
      const AccountBalanceCardData(
        name: '现金',
        iconName: 'account_balance_wallet',
        iconColor: '#3498DB',
        billCount: 15,
        balance: 1250.75,
      ),
      const AccountBalanceCardData(
        name: '银行卡 (6077)',
        iconName: 'account_balance',
        iconColor: '#F97316',
        billCount: 82,
        balance: 23890.12,
      ),
    ];
  }

  @override
  State<AccountBalanceCardWidget> createState() => _AccountBalanceCardWidgetState();
}

class _AccountBalanceCardWidgetState extends State<AccountBalanceCardWidget>
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

    return Container(
      color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      child: Container(
        constraints: widget.size.getHeightConstraints(),
        padding: widget.size.getPadding(),
        child: Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.accounts.length; i++) ...[
                  if (i > 0) SizedBox(height: widget.size.getItemSpacing()),
                  _AccountItemWidget(
                    data: widget.accounts[i],
                    animation: _animation,
                    index: i,
                    size: widget.size,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个账户项
class _AccountItemWidget extends StatelessWidget {
  final AccountBalanceCardData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _AccountItemWidget({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final isNegative = data.balance < 0;

    // 计算每个元素的延迟动画
    final step = 0.12; // 确保不超过 1.0
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * step,
        0.6 + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - itemAnimation.value)),
            child: Container(
              padding: size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: data.iconColorObject.withOpacity(isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.iconData,
                      size: 28,
                      color: data.iconColorObject,
                    ),
                  ),
                  SizedBox(width: size.getItemSpacing()),
                  // 账户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.billCount} 笔账单',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 余额
                  SizedBox(
                    height: 28,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isNegative)
                          SizedBox(
                            height: 20,
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE74C3C),
                                height: 1.0,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 100,
                          height: 28,
                          child: AnimatedFlipCounter(
                            value: data.balance.abs() * itemAnimation.value,
                            fractionDigits: 2,
                            prefix: isNegative ? '' : '¥',
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isNegative
                                  ? const Color(0xFFE74C3C)
                                  : (isDark ? Colors.white : Colors.grey.shade900),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
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
