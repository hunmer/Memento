import 'package:Memento/screens/widgets_gallery/common_widgets/models/account_balance_card_data.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/account_balance_card.dart';

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
        child: Center(
          child: AccountBalanceCardWidget(
            accounts: const [
              AccountBalanceCardData(
                name: '现金',
                iconName: 'account_balance_wallet',
                iconColor: '#3498DB',
                billCount: 15,
                balance: 1250.75,
              ),
              AccountBalanceCardData(
                name: '银行卡 (6077)',
                iconName: 'account_balance',
                iconColor: '#F97316',
                billCount: 82,
                balance: 23890.12,
              ),
              AccountBalanceCardData(
                name: '支付宝',
                iconName: 'payment',
                iconColor: '#0EA5E9',
                billCount: 128,
                balance: 5432.88,
              ),
              AccountBalanceCardData(
                name: '微信钱包',
                iconName: 'chat_bubble',
                iconColor: '#10B981',
                billCount: 97,
                balance: 888.66,
              ),
              AccountBalanceCardData(
                name: '信用卡 (2345)',
                iconName: 'credit_card',
                iconColor: '#EF4444',
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
