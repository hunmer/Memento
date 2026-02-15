import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/account_balance_card_data.dart';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: AccountBalanceCardWidget(
                      size: const SmallSize(),
                      accounts: const [
                        AccountBalanceCardData(
                          name: '现金',
                          iconName: 'account_balance_wallet',
                          iconColor: '#3498DB',
                          billCount: 15,
                          balance: 1250.75,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: AccountBalanceCardWidget(
                      size: const MediumSize(),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 220,
                  child: AccountBalanceCardWidget(
                    size: const WideSize(),
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: AccountBalanceCardWidget(
                      size: const LargeSize(),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 300,
                  child: AccountBalanceCardWidget(
                    size: const Wide2Size(),
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
                        name: '微信',
                        iconName: 'chat',
                        iconColor: '#07C160',
                        billCount: 256,
                        balance: 8765.43,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
