import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/index.dart';

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸 (1x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: StackedBarChartCard(
                      title: 'America',
                      categories: [
                        ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
                        ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
                      ],
                      data: [
                        [
                          ChartSegmentValue(value: 0, categoryIndex: 0),
                          ChartSegmentValue(value: 15, categoryIndex: 0),
                          ChartSegmentValue(value: 20, categoryIndex: 1),
                        ],
                        [
                          ChartSegmentValue(value: 5, categoryIndex: 0),
                          ChartSegmentValue(value: 35, categoryIndex: 1),
                        ],
                        [
                          ChartSegmentValue(value: 5, categoryIndex: 0),
                          ChartSegmentValue(value: 40, categoryIndex: 1),
                        ],
                      ],
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸 (2x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: StackedBarChartCard(
                      title: 'America',
                      categories: [
                        ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
                        ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
                        ChartCategory(name: '2012', color: Color(0xFFA8DFF0)),
                      ],
                      data: [
                        [
                          ChartSegmentValue(value: 0, categoryIndex: 0),
                          ChartSegmentValue(value: 15, categoryIndex: 0),
                          ChartSegmentValue(value: 20, categoryIndex: 1),
                          ChartSegmentValue(value: 30, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 5, categoryIndex: 0),
                          ChartSegmentValue(value: 35, categoryIndex: 1),
                          ChartSegmentValue(value: 15, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 5, categoryIndex: 0),
                          ChartSegmentValue(value: 40, categoryIndex: 1),
                          ChartSegmentValue(value: 10, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 8, categoryIndex: 0),
                          ChartSegmentValue(value: 25, categoryIndex: 1),
                          ChartSegmentValue(value: 17, categoryIndex: 2),
                        ],
                      ],
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸 (2x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: StackedBarChartCard(
                      title: 'America',
                      categories: [
                        ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
                        ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
                        ChartCategory(name: '2012', color: Color(0xFFA8DFF0)),
                      ],
                      data: [
                        [
                          ChartSegmentValue(value: 0, categoryIndex: 0),
                          ChartSegmentValue(value: 15, categoryIndex: 0),
                          ChartSegmentValue(value: 20, categoryIndex: 1),
                          ChartSegmentValue(value: 30, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 5, categoryIndex: 0),
                          ChartSegmentValue(value: 35, categoryIndex: 1),
                          ChartSegmentValue(value: 15, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 5, categoryIndex: 0),
                          ChartSegmentValue(value: 40, categoryIndex: 1),
                          ChartSegmentValue(value: 10, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 8, categoryIndex: 0),
                          ChartSegmentValue(value: 25, categoryIndex: 1),
                          ChartSegmentValue(value: 17, categoryIndex: 2),
                        ],
                        [
                          ChartSegmentValue(value: 6, categoryIndex: 0),
                          ChartSegmentValue(value: 28, categoryIndex: 1),
                          ChartSegmentValue(value: 16, categoryIndex: 2),
                        ],
                      ],
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: StackedBarChartCard(
                    title: 'America - Historical Population Data',
                    categories: [
                      ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
                      ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
                      ChartCategory(name: '2012', color: Color(0xFFA8DFF0)),
                    ],
                    data: [
                      [
                        ChartSegmentValue(value: 0, categoryIndex: 0),
                        ChartSegmentValue(value: 15, categoryIndex: 0),
                        ChartSegmentValue(value: 20, categoryIndex: 1),
                        ChartSegmentValue(value: 30, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 5, categoryIndex: 0),
                        ChartSegmentValue(value: 35, categoryIndex: 1),
                        ChartSegmentValue(value: 15, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 5, categoryIndex: 0),
                        ChartSegmentValue(value: 40, categoryIndex: 1),
                        ChartSegmentValue(value: 10, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 8, categoryIndex: 0),
                        ChartSegmentValue(value: 25, categoryIndex: 1),
                        ChartSegmentValue(value: 17, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 6, categoryIndex: 0),
                        ChartSegmentValue(value: 28, categoryIndex: 1),
                        ChartSegmentValue(value: 16, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 7, categoryIndex: 0),
                        ChartSegmentValue(value: 20, categoryIndex: 1),
                        ChartSegmentValue(value: 13, categoryIndex: 2),
                      ],
                    ],
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: StackedBarChartCard(
                    title: 'America - Complete Historical Population Data',
                    categories: [
                      ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
                      ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
                      ChartCategory(name: '2012', color: Color(0xFFA8DFF0)),
                    ],
                    data: [
                      [
                        ChartSegmentValue(value: 0, categoryIndex: 0),
                        ChartSegmentValue(value: 15, categoryIndex: 0),
                        ChartSegmentValue(value: 20, categoryIndex: 1),
                        ChartSegmentValue(value: 30, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 5, categoryIndex: 0),
                        ChartSegmentValue(value: 35, categoryIndex: 1),
                        ChartSegmentValue(value: 15, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 5, categoryIndex: 0),
                        ChartSegmentValue(value: 40, categoryIndex: 1),
                        ChartSegmentValue(value: 10, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 8, categoryIndex: 0),
                        ChartSegmentValue(value: 25, categoryIndex: 1),
                        ChartSegmentValue(value: 17, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 6, categoryIndex: 0),
                        ChartSegmentValue(value: 28, categoryIndex: 1),
                        ChartSegmentValue(value: 16, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 7, categoryIndex: 0),
                        ChartSegmentValue(value: 20, categoryIndex: 1),
                        ChartSegmentValue(value: 13, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 12, categoryIndex: 0),
                        ChartSegmentValue(value: 18, categoryIndex: 1),
                        ChartSegmentValue(value: 35, categoryIndex: 2),
                      ],
                      [
                        ChartSegmentValue(value: 5, categoryIndex: 0),
                        ChartSegmentValue(value: 45, categoryIndex: 1),
                        ChartSegmentValue(value: 15, categoryIndex: 2),
                      ],
                    ],
                    size: const Wide2Size(),
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
