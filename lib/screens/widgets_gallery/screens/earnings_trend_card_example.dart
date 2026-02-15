import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/earnings_trend_card.dart';

/// 收益趋势卡片示例
class EarningsTrendCardExample extends StatelessWidget {
  const EarningsTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收益趋势卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF2F6),
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
                    child: EarningsTrendCardWidget(
                      size: const SmallSize(),
                      title: 'Expected earnings',
                      value: 682.5,
                      currency: '€',
                      percentage: 2.45,
                      chartData: const [80, 90, 60, 40],
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
                    child: EarningsTrendCardWidget(
                      size: const MediumSize(),
                      title: 'Expected earnings',
                      value: 682.5,
                      currency: '€',
                      percentage: 2.45,
                      chartData: const [80, 90, 60, 40, 110, 50, 40],
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
                    child: EarningsTrendCardWidget(
                      size: const LargeSize(),
                      title: 'Expected earnings',
                      value: 682.5,
                      currency: '€',
                      percentage: 2.45,
                      chartData: const [80, 90, 60, 40, 110, 110, 50, 40, 30, 70],
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
