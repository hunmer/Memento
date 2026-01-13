import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/monthly_bill_card_data.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/monthly_bill_card.dart';

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
            data: MonthlyBillCardData(
              title: '6月账单',
              income: 1024.00,
              expense: 2048.00,
              balance: -1024.00,
            ),
          ),
        ),
      ),
    );
  }
}
