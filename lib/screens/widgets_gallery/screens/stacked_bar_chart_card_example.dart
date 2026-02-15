import 'package:flutter/material.dart';
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
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 200,
                    child: StackedBarChartCard(
                      title: 'America',
                      description: 'Lorem ipsum dolor.',
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
                      subtitle: 'Population',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 280,
                    child: StackedBarChartCard(
                      title: 'America',
                      description: 'Lorem ipsum dolor sit amet.',
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
                      subtitle: 'Historic Data',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 400,
                    height: 350,
                    child: StackedBarChartCard(
                      title: 'America',
                      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
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
                      subtitle: 'Historic World Population',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 380,
                  child: StackedBarChartCard(
                    title: 'America - Historical Population Data',
                    description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.',
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
                    subtitle: 'Historic World Population Analysis',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 480,
                  child: StackedBarChartCard(
                    title: 'America - Complete Historical Population Data',
                    description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
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
                    subtitle: 'Historic World Population Comprehensive Analysis',
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
