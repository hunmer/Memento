import 'package:flutter/material.dart';

/// 统计图表示例
class StatisticsExample extends StatelessWidget {
  const StatisticsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计图表'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个统计图表组件，支持多种图表类型。'),
            const SizedBox(height: 24),
            Text(
              '支持的图表类型',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 折线图'),
            const Text('• 柱状图'),
            const Text('• 饼图'),
            const Text('• 面积图'),
          ],
        ),
      ),
    );
  }
}
