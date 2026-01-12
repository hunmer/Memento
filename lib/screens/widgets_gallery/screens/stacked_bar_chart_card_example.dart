import 'package:Memento/widgets/common/index.dart';
import 'package:flutter/material.dart';

/// 堆叠柱状图卡片示例
///
/// 展示 StackedBarChartCard 组件的使用方法
class StackedBarChartCardExample extends StatelessWidget {
  const StackedBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('堆叠柱状图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: StackedBarChartCard(
            title: 'America',
            description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.',
            categories: [
              ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
              ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
              ChartCategory(name: '2012', color: Color(0xFFA8DFF0)),
            ],
            data: [
                // 第1列
                [
                  ChartSegmentValue(value: 0, categoryIndex: 0),
                  ChartSegmentValue(value: 15, categoryIndex: 0),
                  ChartSegmentValue(value: 20, categoryIndex: 1),
                  ChartSegmentValue(value: 30, categoryIndex: 2),
                  ChartSegmentValue(value: 25, categoryIndex: 0),
                ],
                // 第2列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 35, categoryIndex: 1),
                  ChartSegmentValue(value: 15, categoryIndex: 2),
                  ChartSegmentValue(value: 45, categoryIndex: 0),
                ],
                // 第3列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 40, categoryIndex: 1),
                  ChartSegmentValue(value: 10, categoryIndex: 2),
                  ChartSegmentValue(value: 45, categoryIndex: 0),
                ],
                // 第4列
                [
                  ChartSegmentValue(value: 8, categoryIndex: 0),
                  ChartSegmentValue(value: 25, categoryIndex: 1),
                  ChartSegmentValue(value: 17, categoryIndex: 2),
                  ChartSegmentValue(value: 50, categoryIndex: 0),
                ],
                // 第5列
                [
                  ChartSegmentValue(value: 6, categoryIndex: 0),
                  ChartSegmentValue(value: 28, categoryIndex: 1),
                  ChartSegmentValue(value: 16, categoryIndex: 2),
                  ChartSegmentValue(value: 50, categoryIndex: 0),
                ],
                // 第6列
                [
                  ChartSegmentValue(value: 7, categoryIndex: 0),
                  ChartSegmentValue(value: 20, categoryIndex: 1),
                  ChartSegmentValue(value: 13, categoryIndex: 2),
                  ChartSegmentValue(value: 60, categoryIndex: 0),
                ],
                // 第7列
                [
                  ChartSegmentValue(value: 12, categoryIndex: 0),
                  ChartSegmentValue(value: 18, categoryIndex: 1),
                  ChartSegmentValue(value: 35, categoryIndex: 2),
                  ChartSegmentValue(value: 35, categoryIndex: 0),
                ],
                // 第8列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 45, categoryIndex: 1),
                  ChartSegmentValue(value: 15, categoryIndex: 2),
                  ChartSegmentValue(value: 35, categoryIndex: 0),
                ],
                // 第9列
                [
                  ChartSegmentValue(value: 9, categoryIndex: 0),
                  ChartSegmentValue(value: 10, categoryIndex: 1),
                  ChartSegmentValue(value: 41, categoryIndex: 2),
                  ChartSegmentValue(value: 40, categoryIndex: 0),
                ],
                // 第10列
                [
                  ChartSegmentValue(value: 10, categoryIndex: 0),
                  ChartSegmentValue(value: 15, categoryIndex: 1),
                  ChartSegmentValue(value: 35, categoryIndex: 2),
                  ChartSegmentValue(value: 40, categoryIndex: 0),
                ],
                // 第11列
                [
                  ChartSegmentValue(value: 6, categoryIndex: 0),
                  ChartSegmentValue(value: 40, categoryIndex: 1),
                  ChartSegmentValue(value: 24, categoryIndex: 2),
                  ChartSegmentValue(value: 30, categoryIndex: 0),
                ],
                // 第12列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 45, categoryIndex: 1),
                  ChartSegmentValue(value: 20, categoryIndex: 2),
                  ChartSegmentValue(value: 30, categoryIndex: 0),
                ],
            ],
            subtitle: 'Historic World Population',
          ),
        ),
      ),
    );
  }
}
