import 'package:Memento/screens/widgets_gallery/common_widgets/models/trend_list_card_data.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/trend_list_card.dart';

/// 趋势列表卡片示例
class TrendListCardExample extends StatelessWidget {
  const TrendListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('趋势列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TrendListCardWidget(
            data: TrendListCardData(
              title: 'Stocks',
              iconName: 'monetization_on',
              items: [
                TrendItemData(
                  symbol: 'ELM.35',
                  value: 7877.05,
                  percentChange: 0.37,
                  valueChange: 29.06,
                  isPositive: true,
                ),
                TrendItemData(
                  symbol: 'URP.20',
                  value: 5009.71,
                  percentChange: -0.25,
                  valueChange: -12.50,
                  isPositive: false,
                ),
                TrendItemData(
                  symbol: 'CAC.40',
                  value: 1958.08,
                  percentChange: 0.52,
                  valueChange: 10.13,
                  isPositive: true,
                ),
                TrendItemData(
                  symbol: 'YET',
                  value: 8023.26,
                  percentChange: 0.52,
                  valueChange: 41.75,
                  isPositive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
