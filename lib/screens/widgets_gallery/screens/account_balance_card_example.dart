import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 账户余额卡片示例
class AccountBalanceCardExample extends StatelessWidget {
  const AccountBalanceCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('账户余额卡片')),
      body: Container(
        color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
        child: const Center(
          child: AccountBalanceCardWidget(
            accounts: [
              AccountData(
                name: '现金',
                icon: Icons.account_balance_wallet,
                iconColor: Color(0xFF3498DB),
                billCount: 15,
                balance: 1250.75,
              ),
              AccountData(
                name: '银行卡 (6077)',
                icon: Icons.account_balance,
                iconColor: Color(0xFFF97316),
                billCount: 82,
                balance: 23890.12,
              ),
              AccountData(
                name: '支付宝',
                icon: Icons.payment,
                iconColor: Color(0xFF0EA5E9),
                billCount: 128,
                balance: 5432.88,
              ),
              AccountData(
                name: '微信钱包',
                icon: Icons.chat_bubble,
                iconColor: Color(0xFF10B981),
                billCount: 97,
                balance: 888.66,
              ),
              AccountData(
                name: '信用卡 (2345)',
                icon: Icons.credit_card,
                iconColor: Color(0xFFEF4444),
                billCount: 45,
                balance: -4500.00,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 账户数据模型
class AccountData {
  final String name;
  final IconData icon;
  final Color iconColor;
  final int billCount;
  final double balance;

  const AccountData({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.billCount,
    required this.balance,
  });
}

/// 账户余额卡片小组件
class AccountBalanceCardWidget extends StatefulWidget {
  final List<AccountData> accounts;

  const AccountBalanceCardWidget({
    super.key,
    required this.accounts,
  });

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
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.accounts.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _AccountItemWidget(
              data: widget.accounts[i],
              animation: _animation,
              index: i,
            ),
          ],
        ],
      ),
    );
  }
}

/// 单个账户项
class _AccountItemWidget extends StatelessWidget {
  final AccountData data;
  final Animation<double> animation;
  final int index;

  const _AccountItemWidget({
    required this.data,
    required this.animation,
    required this.index,
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
              padding: const EdgeInsets.all(16),
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
                      color: data.iconColor.withOpacity(isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      size: 28,
                      color: data.iconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
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
