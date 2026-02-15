import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/dual_bar_chart_card.dart';

/// 双柱状图统计卡片示例
class DualBarChartCardExample extends StatelessWidget {
  const DualBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('双柱状图统计卡片')),
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
                    child: DualBarChartCardWidget(
                      title: '血压监测',
                      date: 'Jan 12, 2028',
                      primaryValue: 129,
                      secondaryValue: 68,
                      primaryLabel: 'sys',
                      secondaryLabel: 'dia',
                      warningStage: 'Stage 2',
                      chartData: const [
                        DualBarData(primary: 32, secondary: 24),
                        DualBarData(primary: 12, secondary: 32),
                        DualBarData(primary: 20, secondary: 16),
                      ],
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
                    child: DualBarChartCardWidget(
                      title: '血压监测',
                      date: 'Jan 12, 2028',
                      primaryValue: 129,
                      secondaryValue: 68,
                      primaryLabel: 'sys',
                      secondaryLabel: 'dia',
                      warningStage: 'Stage 2',
                      chartData: const [
                        DualBarData(primary: 32, secondary: 24),
                        DualBarData(primary: 12, secondary: 32),
                        DualBarData(primary: 20, secondary: 16),
                        DualBarData(primary: 32, secondary: 28),
                        DualBarData(primary: 36, secondary: 40),
                        DualBarData(primary: 44, secondary: 40),
                        DualBarData(primary: 16, secondary: 32),
                        DualBarData(primary: 40, secondary: 28),
                      ],
                      size: const MediumSize(),
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
                    child: DualBarChartCardWidget(
                      title: '血压监测',
                      date: 'Jan 12, 2028',
                      primaryValue: 129,
                      secondaryValue: 68,
                      primaryLabel: 'sys',
                      secondaryLabel: 'dia',
                      warningStage: 'Stage 2',
                      chartData: const [
                        DualBarData(primary: 32, secondary: 24),
                        DualBarData(primary: 12, secondary: 32),
                        DualBarData(primary: 20, secondary: 16),
                        DualBarData(primary: 32, secondary: 28),
                        DualBarData(primary: 36, secondary: 40),
                        DualBarData(primary: 44, secondary: 40),
                        DualBarData(primary: 16, secondary: 32),
                        DualBarData(primary: 40, secondary: 28),
                        DualBarData(primary: 32, secondary: 36),
                        DualBarData(primary: 16, secondary: 48),
                      ],
                      size: const LargeSize(),
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
