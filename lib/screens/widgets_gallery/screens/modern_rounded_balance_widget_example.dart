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
                    child: ModernRoundedBalanceCard(
                      title: 'Card Balance',
                      balance: 1682.55,
                      available: 8317.45,
                      weeklyData: const [0.45, 0.65, 0.35, 0.75],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: ModernRoundedBalanceCard(
                      title: 'Card Balance',
                      balance: 1682.55,
                      available: 8317.45,
                      weeklyData: const [0.45, 0.65, 0.35, 0.75, 0.70],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: ModernRoundedBalanceCard(
                      title: 'Card Balance',
                      balance: 1682.55,
                      available: 8317.45,
                      weeklyData: const [0.45, 0.65, 0.35, 0.75, 0.70, 0.90, 0.30],
                    ),
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
