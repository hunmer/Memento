import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/circular_metrics_card.dart';

/// 环形指标卡片示例
class CircularMetricsCardExample extends StatelessWidget {
  const CircularMetricsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('环形指标卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CircularMetricsCardWidget(
            title: 'Overview',
            metrics: [
              MetricData(
                icon: Icons.person,
                value: '12d 23hrs',
                label: 'To complete',
                progress: 0.75,
                color: Color(0xFF34D399), // Green
              ),
              MetricData(
                icon: Icons.pets,
                value: '24',
                label: 'Team',
                progress: 0.60,
                color: Color(0xFFFB7185), // Pink
              ),
              MetricData(
                icon: Icons.savings,
                value: '20.5k',
                label: 'Budget left',
                progress: 0.40,
                color: Color(0xFFFBBF24), // Orange
              ),
              MetricData(
                icon: Icons.inventory_2,
                value: '384',
                label: 'Assigned',
                progress: 0.80,
                color: Color(0xFF6366F1), // Blue
              ),
            ],
          ),
        ),
      ),
    );
  }
}
