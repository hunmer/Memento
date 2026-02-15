import 'package:flutter/material.dart';
import 'package:Memento/widgets/statistics/statistics.dart';

/// 统计图表示例
class StatisticsExample extends StatefulWidget {
  const StatisticsExample({super.key});

  @override
  State<StatisticsExample> createState() => _StatisticsExampleState();
}

class _StatisticsExampleState extends State<StatisticsExample> {
  // 演示数据配色方案
  static const List<Color> _colorPalette = [
    Color(0xFF60A5FA), // blue
    Color(0xFF4ADE80), // green
    Color(0xFF818CF8), // indigo
    Color(0xFFFB923C), // orange
    Color(0xFFF87171), // red
    Color(0xFFFACC15), // yellow
    Color(0xFF2DD4BF), // teal
    Color(0xFFA78BFA), // purple
  ];

  // 尺寸模式
  String _sizeMode = 'small';

  // 生成演示饼图数据
  List<DistributionData> get _pieChartData => [
        DistributionData(label: '工作', value: 35, color: _colorPalette[0]),
        DistributionData(label: '学习', value: 25, color: _colorPalette[1]),
        DistributionData(label: '娱乐', value: 20, color: _colorPalette[2]),
        DistributionData(label: '运动', value: 12, color: _colorPalette[3]),
        DistributionData(label: '其他', value: 8, color: _colorPalette[4]),
      ];

  // 生成演示排行榜数据
  List<RankingData> get _rankingData => [
        RankingData(label: '项目 A', value: 156, color: _colorPalette[0]),
        RankingData(label: '项目 B', value: 132, color: _colorPalette[1]),
        RankingData(label: '项目 C', value: 98, color: _colorPalette[2]),
        RankingData(label: '项目 D', value: 76, color: _colorPalette[3]),
        RankingData(label: '项目 E', value: 54, color: _colorPalette[4]),
      ];

  // 生成演示趋势图数据
  List<TimeSeriesData> get _timeSeriesData {
    final now = DateTime.now();
    return [
      TimeSeriesData(
        label: '本周',
        color: _colorPalette[0],
        points: List.generate(7, (i) {
          return TimeSeriesPoint(
            date: now.subtract(Duration(days: 6 - i)),
            value: 30 + (i * 10) + ((i % 3) * 15),
          );
        }),
      ),
      TimeSeriesData(
        label: '上周',
        color: _colorPalette[3],
        points: List.generate(7, (i) {
          return TimeSeriesPoint(
            date: now.subtract(Duration(days: 13 - i)),
            value: 25 + (i * 8) + ((i % 2) * 20),
          );
        }),
      ),
    ];
  }

  // 生成24小时分布数据
  List<TimeSeriesPoint> get _hourlyData {
    final now = DateTime.now();
    return List.generate(24, (hour) {
      return TimeSeriesPoint(
        date: DateTime(now.year, now.month, now.day, hour),
        value: _generateHourlyValue(hour),
      );
    });
  }

  double _generateHourlyValue(int hour) {
    // 模拟一天中的活动分布
    if (hour >= 9 && hour <= 18) return 40 + (hour % 3) * 15;
    if (hour >= 19 && hour <= 22) return 60;
    if (hour >= 6 && hour <= 8) return 25;
    return 5;
  }

  /// 获取宽度
  double _getWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (_sizeMode) {
      case 'small':
        return 360;
      case 'medium':
        return 440;
      case 'mediumWide':
        return screenWidth - 32;
      case 'large':
        return 520;
      case 'largeWide':
        return screenWidth - 32;
      default:
        return 360;
    }
  }

  /// 是否占满宽度
  bool _isFullWidth() {
    return _sizeMode == 'mediumWide' || _sizeMode == 'largeWide';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计图表'),
      ),
      body: Column(
        children: [
          // 尺寸切换按钮
          _buildSizeSelector(theme),
          const Divider(height: 1),
          // 内容
          Expanded(
            child: _isFullWidth()
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题说明
                        Text(
                          'Statistics Components',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '通用统计图表组件库，支持多种数据可视化方式。',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 饼图示例
                        buildStatisticsCard(
                          context: context,
                          title: '分布饼图',
                          subtitle: 'DistributionPieChart',
                          child: DistributionPieChart(
                            data: _pieChartData,
                            colorPalette: _colorPalette,
                            centerText: '100',
                            centerSubtext: '总计小时',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 排行榜示例
                        buildStatisticsCard(
                          context: context,
                          title: '排行榜',
                          subtitle: 'RankingList',
                          child: RankingList(
                            data: _rankingData,
                            colorPalette: _colorPalette,
                            valueLabel: '小时',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 趋势图示例
                        buildStatisticsCard(
                          context: context,
                          title: '时间序列趋势图',
                          subtitle: 'TimeSeriesChart',
                          child: TimeSeriesChart(
                            series: _timeSeriesData,
                            height: 220,
                            showDots: true,
                            colorPalette: _colorPalette,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 24小时分布示例
                        buildStatisticsCard(
                          context: context,
                          title: '24小时分布',
                          subtitle: 'HourlyDistributionBar',
                          child: HourlyDistributionBar(
                            hourlyData: _hourlyData,
                            colorPalette: _colorPalette,
                            height: 50,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 使用说明
                        Text(
                          '组件说明',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildUsageGuide(context),
                      ],
                    ),
                  )
                : Center(
                    child: SizedBox(
                      width: _getWidth(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题说明
                            Text(
                              'Statistics Components',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '通用统计图表组件库，支持多种数据可视化方式。',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 饼图示例
                            buildStatisticsCard(
                              context: context,
                              title: '分布饼图',
                              subtitle: 'DistributionPieChart',
                              child: DistributionPieChart(
                                data: _pieChartData,
                                colorPalette: _colorPalette,
                                centerText: '100',
                                centerSubtext: '总计小时',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 排行榜示例
                            buildStatisticsCard(
                              context: context,
                              title: '排行榜',
                              subtitle: 'RankingList',
                              child: RankingList(
                                data: _rankingData,
                                colorPalette: _colorPalette,
                                valueLabel: '小时',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 趋势图示例
                            buildStatisticsCard(
                              context: context,
                              title: '时间序列趋势图',
                              subtitle: 'TimeSeriesChart',
                              child: TimeSeriesChart(
                                series: _timeSeriesData,
                                height: 200,
                                showDots: true,
                                colorPalette: _colorPalette,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 24小时分布示例
                            buildStatisticsCard(
                              context: context,
                              title: '24小时分布',
                              subtitle: 'HourlyDistributionBar',
                              child: HourlyDistributionBar(
                                hourlyData: _hourlyData,
                                colorPalette: _colorPalette,
                                height: 40,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 使用说明
                            Text(
                              '组件说明',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _buildUsageGuide(context),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 尺寸选择器
  Widget _buildSizeSelector(ThemeData theme) {
    final sizes = [
      {'value': 'small', 'label': '小尺寸'},
      {'value': 'medium', 'label': '中尺寸'},
      {'value': 'mediumWide', 'label': '中宽'},
      {'value': 'large', 'label': '大尺寸'},
      {'value': 'largeWide', 'label': '大宽'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: sizes.map((size) {
          final isSelected = _sizeMode == size['value'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(size['label']!),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _sizeMode = size['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsageGuide(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuideItem(
              context,
              title: 'DistributionPieChart',
              description: '展示各类别在总量中的占比分布，支持中心数值显示和图例。',
            ),
            const Divider(height: 24),
            _buildGuideItem(
              context,
              title: 'RankingList',
              description: '展示排行榜数据，带进度条动画和数值翻转效果。',
            ),
            const Divider(height: 24),
            _buildGuideItem(
              context,
              title: 'TimeSeriesChart',
              description: '展示时间序列趋势变化，支持多条数据线对比。',
            ),
            const Divider(height: 24),
            _buildGuideItem(
              context,
              title: 'HourlyDistributionBar',
              description: '展示24小时活动分布，可显示每小时的主要活动标签。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(BuildContext context, {required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
