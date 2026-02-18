import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/monthly_bill_card_data.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/monthly_bill_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
                    child: MonthlyBillCardWidget(
                      data: const MonthlyBillCardData(
                        title: '6月账单',
                        income: 1024.00,
                        expense: 2048.00,
                        balance: -1024.00,
                      ),
                      size: const SmallSize(),
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
                    child: MonthlyBillCardWidget(
                      data: const MonthlyBillCardData(
                        title: '6月账单',
                        income: 1024.00,
                        expense: 2048.00,
                        balance: -1024.00,
                      ),
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: MonthlyBillCardWidget(
                      data: const MonthlyBillCardData(
                        title: '6月账单',
                        income: 1024.00,
                        expense: 2048.00,
                        balance: -1024.00,
                      ),
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: MonthlyBillCardWidget(
                    data: const MonthlyBillCardData(
                      title: '6月账单 - 详细分析',
                      income: 1024.00,
                      expense: 2048.00,
                      balance: -1024.00,
                    ),
                    size: const Wide2Size(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: MonthlyBillCardWidget(
                    data: const MonthlyBillCardData(
                      title: '6月账单 - 完整财务报告',
                      income: 1024.00,
                      expense: 2048.00,
                      balance: -1024.00,
                    ),
                    size: const Wide3Size(),
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
