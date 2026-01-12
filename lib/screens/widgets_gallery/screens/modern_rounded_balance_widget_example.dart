import 'package:Memento/widgets/common/modern_rounded_balance_card.dart';
import 'package:flutter/material.dart';

/// 余额卡片示例
class ModernRoundedBalanceWidgetExample extends StatelessWidget {
  const ModernRoundedBalanceWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('余额卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        child: const Center(
          child: ModernRoundedBalanceCard(
            title: 'Card Balance',
            balance: 1682.55,
            available: 8317.45,
            weeklyData: [0.45, 0.65, 0.35, 0.75, 0.70, 0.90, 0.30],
          ),
        ),
      ),
    );
  }
}
