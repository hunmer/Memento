import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/checkin_item.dart';
import 'dart:math' as math;

class CheckinGroupPieChart extends StatefulWidget {
  final List<CheckinItem> checkinItems;

  const CheckinGroupPieChart({
    super.key,
    required this.checkinItems,
  });

  @override
  State<CheckinGroupPieChart> createState() => _CheckinGroupPieChartState();
}

class _CheckinGroupPieChartState extends State<CheckinGroupPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupData = _prepareGroupData();

    if (groupData.isEmpty) {
      return Center(
        child: Text(
          '暂无打卡分组数据',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Row(
      children: [
        // 饼图
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _buildSections(groupData),
            ),
          ),
        ),
        
        // 图例
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupData.asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value.group;
              final count = entry.value.count;
              final percent = entry.value.percentage;
              final color = _getGroupColor(index);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        group,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '$count (${(percent * 100).toStringAsFixed(1)}%)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(List<GroupData> groupData) {
    return groupData.asMap().entries.map((entry) {
      final index = entry.key;
      final isSelected = index == touchedIndex;
      final data = entry.value;
      final color = _getGroupColor(index);
      
      return PieChartSectionData(
        color: color,
        value: data.percentage * 100,
        title: '${(data.percentage * 100).toStringAsFixed(1)}%',
        radius: isSelected ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Color _getGroupColor(int index) {
    // 预定义一组颜色
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    // 如果超出预定义颜色范围，则随机生成颜色
    if (index >= colors.length) {
      return Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    }

    return colors[index];
  }

  List<GroupData> _prepareGroupData() {
    // 统计各分组的打卡项数量
    Map<String, int> groupCounts = {};
    int totalItems = widget.checkinItems.length;

    if (totalItems == 0) {
      return [];
    }

    for (var item in widget.checkinItems) {
      final group = item.group.isEmpty ? '未分组' : item.group;
      groupCounts[group] = (groupCounts[group] ?? 0) + 1;
    }

    // 转换为百分比数据
    List<GroupData> result = groupCounts.entries.map((entry) {
      return GroupData(
        group: entry.key,
        count: entry.value,
        percentage: entry.value / totalItems,
      );
    }).toList();

    // 按数量排序
    result.sort((a, b) => b.count.compareTo(a.count));

    return result;
  }
}

class GroupData {
  final String group;
  final int count;
  final double percentage;

  GroupData({
    required this.group,
    required this.count,
    required this.percentage,
  });
}