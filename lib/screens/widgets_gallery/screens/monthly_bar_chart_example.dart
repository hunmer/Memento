import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 月度柱状图统计卡片示例
class MonthlyBarChartExample extends StatelessWidget {
  const MonthlyBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('月度柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEBF1F5),
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
                    child: MonthlyBarChartCard(
                      totalValue: 890.93,
                      currentMonth: 5,
                      monthlyData: const [
                        MonthlyData(month: 'Jan', value: 35),
                        MonthlyData(month: 'Feb', value: 60),
                        MonthlyData(month: 'Mar', value: 45),
                        MonthlyData(month: 'Apr', value: 55),
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
                    child: MonthlyBarChartCard(
                      totalValue: 890.93,
                      currentMonth: 5,
                      monthlyData: const [
                        MonthlyData(month: 'Jan', value: 35),
                        MonthlyData(month: 'Feb', value: 60),
                        MonthlyData(month: 'Mar', value: 45),
                        MonthlyData(month: 'Apr', value: 55),
                        MonthlyData(month: 'May', value: 40),
                        MonthlyData(month: 'Jun', value: 80),
                        MonthlyData(month: 'Jul', value: 38),
                        MonthlyData(month: 'Aug', value: 65),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 300,
                    child: MonthlyBarChartCard(
                      totalValue: 890.93,
                      currentMonth: 5,
                      monthlyData: const [
                        MonthlyData(month: 'Jan', value: 35),
                        MonthlyData(month: 'Feb', value: 60),
                        MonthlyData(month: 'Mar', value: 45),
                        MonthlyData(month: 'Apr', value: 55),
                        MonthlyData(month: 'May', value: 40),
                        MonthlyData(month: 'Jun', value: 80),
                        MonthlyData(month: 'Jul', value: 38),
                        MonthlyData(month: 'Aug', value: 65),
                        MonthlyData(month: 'Sep', value: 25),
                        MonthlyData(month: 'Oct', value: 55),
                        MonthlyData(month: 'Nov', value: 30),
                        MonthlyData(month: 'Dec', value: 45),
                      ],
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
