import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillStatisticsCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const BillStatisticsCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '账单概览',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '收入',
                  totalIncome,
                  Colors.green,
                  Icons.arrow_downward,
                ),
                _buildStatItem(
                  '支出',
                  totalExpense,
                  Colors.red,
                  Icons.arrow_upward,
                ),
                _buildStatItem(
                  '结余',
                  balance,
                  balance >= 0 ? Colors.blue : Colors.orange,
                  Icons.account_balance_wallet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final formatter = NumberFormat.currency(symbol: '¥', decimalDigits: 2);

    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
