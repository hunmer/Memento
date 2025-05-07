import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/activity_service.dart';
import '../models/activity_record.dart';

/// 活动统计页面
class ActivityStatisticsScreen extends StatefulWidget {
  final ActivityService activityService;

  const ActivityStatisticsScreen({
    super.key,
    required this.activityService,
  });

  @override
  State<ActivityStatisticsScreen> createState() => _ActivityStatisticsScreenState();
}

class _ActivityStatisticsScreenState extends State<ActivityStatisticsScreen> {
  // 时间范围选择
  String _selectedRange = '本日';
  final List<String> _timeRanges = ['本日', '本周', '本月', '本年', '自定义范围'];
  
  // 日期范围
  DateTime? _startDate;
  DateTime? _endDate;

  // 活动数据
  List<ActivityRecord> _activities = [];
  bool _isLoading = false;

  // 选中的标签及其对应的活动
  String? _selectedTag;
  List<ActivityRecord> _selectedTagActivities = [];

  @override
  void initState() {
    super.initState();
    _updateDateRange('本日');
  }

  // 更新日期范围并加载数据
  Future<void> _updateDateRange(String range) async {
    // 切换日期范围时，重置选中的标签和活动列表
    setState(() {
      _selectedTag = null;
      _selectedTagActivities = [];
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime start;
    DateTime end;

    switch (range) {
      case '本日':
        start = today;
        end = todayEnd;
        break;
      case '本周':
        // 获取本周一
        start = today.subtract(Duration(days: now.weekday - 1));
        end = todayEnd;
        break;
      case '本月':
        start = DateTime(now.year, now.month, 1);
        end = todayEnd;
        break;
      case '本年':
        start = DateTime(now.year, 1, 1);
        end = todayEnd;
        break;
      case '自定义范围':
        // 保持当前日期范围，等待用户选择
        if (_startDate == null || _endDate == null) {
          start = today;
          end = todayEnd;
        } else {
          start = _startDate!;
          end = _endDate!;
        }
        
        setState(() {
          _selectedRange = range;
          _startDate = start;
          _endDate = end;
        });
        
        await _showDateRangePicker();
        return; // 在日期选择器回调中会更新数据
        
      default:
        start = today;
        end = todayEnd;
    }

    setState(() {
      _selectedRange = range;
      _startDate = start;
      _endDate = end;
    });

    await _loadActivities();
  }

  // 显示日期范围选择器
  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // 确保初始日期范围不超过今天
    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? now;
    final validEnd = initialEnd.isAfter(lastDate) ? lastDate : initialEnd;
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: validEnd,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      await _loadActivities();
    }
  }

  // 加载指定日期范围内的活动数据
  Future<void> _loadActivities() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final activities = <ActivityRecord>[];
      
      // 遍历日期范围内的每一天
      for (var date = _startDate!;
          date.isBefore(_endDate!.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        final dailyActivities = await widget.activityService.getActivitiesForDate(date);
        activities.addAll(dailyActivities);
      }

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败：$e')),
        );
      }
    }
  }

  // 计算活动时间分布数据（24小时）
  List<int> _calculateHourlyDistribution() {
    final hourlyMinutes = List<int>.filled(24, 0);
    
    if (_selectedRange != '本日') return hourlyMinutes;

    for (var activity in _activities) {
      final startHour = activity.startTime.hour;
      final endHour = activity.endTime.hour;
      final startMinute = activity.startTime.minute;
      final endMinute = activity.endTime.minute;

      if (startHour == endHour) {
        // 活动在同一小时内
        hourlyMinutes[startHour] += activity.durationInMinutes;
      } else {
        // 活动跨越多个小时
        // 第一个小时的分钟数
        hourlyMinutes[startHour] += 60 - startMinute;
        
        // 中间的完整小时
        for (var hour = startHour + 1; hour < endHour; hour++) {
          hourlyMinutes[hour] += 60;
        }
        
        // 最后一个小时的分钟数
        if (endHour < 24) {
          hourlyMinutes[endHour] += endMinute;
        }
      }
    }

    return hourlyMinutes;
  }

  // 计算活动类型占比数据
  List<MapEntry<String, int>> _calculateActivityDistribution() {
    final Map<String, int> tagMinutes = {};
    
    for (var activity in _activities) {
      final duration = activity.durationInMinutes;
      
      if (activity.tags.isEmpty) {
        // 无标签的活动归类为"其他"
        tagMinutes['其他'] = (tagMinutes['其他'] ?? 0) + duration;
      } else {
        // 将时间平均分配给每个标签
        final minutesPerTag = duration ~/ activity.tags.length;
        for (var tag in activity.tags) {
          tagMinutes[tag] = (tagMinutes[tag] ?? 0) + minutesPerTag;
        }
      }
    }

    // 转换为列表并排序
    final sortedEntries = tagMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 如果超过5个类别，将剩余的合并为"其他"
    if (sortedEntries.length > 5) {
      final topEntries = sortedEntries.take(4).toList();
      final otherMinutes = sortedEntries
          .skip(4)
          .fold(0, (sum, entry) => sum + entry.value);
      topEntries.add(MapEntry('其他', otherMinutes));
      return topEntries;
    }

    return sortedEntries;
  }

  // 根据标签筛选活动
  List<ActivityRecord> _getActivitiesByTag(String tag) {
    if (tag == '其他') {
      // 查找没有标签的活动
      return _activities.where((activity) => activity.tags.isEmpty).toList();
    } else {
      // 查找包含指定标签的活动
      return _activities.where((activity) => activity.tags.contains(tag)).toList();
    }
  }

  // 选择标签并显示相关活动
  void _selectTag(String tag) {
    if (_selectedTag == tag) {
      // 再次点击同一个标签时，取消选择
      setState(() {
        _selectedTag = null;
        _selectedTagActivities = [];
      });
    } else {
      // 选择新标签
      final activities = _getActivitiesByTag(tag);
      setState(() {
        _selectedTag = tag;
        _selectedTagActivities = activities;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 时间范围选择器
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeRanges.map((range) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(range),
                      selected: _selectedRange == range,
                      onSelected: (selected) {
                        if (selected) _updateDateRange(range);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 显示选中的日期范围
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${DateFormat('yyyy-MM-dd').format(_startDate!)} 至 ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          // 数据加载中显示进度条
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 仅在选择"本日"时显示活动时间分布
                    if (_selectedRange == '本日') ...[
                      _buildSectionTitle('活动时间分布'),
                      SizedBox(
                        height: 200,
                        child: _buildTimeDistributionChart(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // 活动占比统计
                    _buildSectionTitle('活动占比统计'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 饼图
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 250,
                            child: _buildActivityPieChart(),
                          ),
                        ),
                        // 图例和总时长
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 250,
                            child: _buildPieChartLegend(),
                          ),
                        ),
                      ],
                    ),
                    
                    // 选中标签的活动列表
                    if (_selectedTag != null) 
                      _buildActivityList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeDistributionChart() {
    final hourlyData = _calculateHourlyDistribution();
    final maxMinutes = hourlyData.reduce((a, b) => a > b ? a : b).toDouble();

    final List<BarChartGroupData> barGroups = List.generate(24, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hourlyData[index].toDouble(),
            color: Theme.of(context).primaryColor,
            width: 12,
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxMinutes > 0 ? maxMinutes : 60,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${group.x}时: ${rod.toY.toInt()}分钟',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 6 == 0) {
                  return Text('${value.toInt()}:00');
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}分');
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // 用于整个页面共享的颜色列表
  final List<Color> _chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
  ];

  Widget _buildActivityPieChart() {
    final activityData = _calculateActivityDistribution();
    if (activityData.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final totalMinutes = activityData.fold(0, (sum, entry) => sum + entry.value);
    if (totalMinutes <= 0) {
      return const Center(child: Text('暂无活动时间数据'));
    }
    
    return PieChart(
      PieChartData(
        sections: List.generate(activityData.length, (index) {
          final entry = activityData[index];
          final percentage = (entry.value / totalMinutes * 100).toStringAsFixed(1);
          final isSelected = _selectedTag == entry.key;
          
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: percentage + '%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            color: _chartColors[index % _chartColors.length],
            radius: isSelected ? 90 : 80, // 选中时略大一些
            badgeWidget: isSelected 
              ? const Icon(Icons.check_circle, color: Colors.white, size: 18)
              : null,
            badgePositionPercentageOffset: 0.98,
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (mounted && event is FlTapUpEvent && 
                pieTouchResponse != null && 
                pieTouchResponse.touchedSection != null) {
              final sectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              if (sectionIndex >= 0 && sectionIndex < activityData.length) {
                setState(() {
                  _selectTag(activityData[sectionIndex].key);
                });
              }
            }
          },
        ),
      ),
    );
  }

  // 构建饼图右侧的图例和总时长
  Widget _buildPieChartLegend() {
    final activityData = _calculateActivityDistribution();
    if (activityData.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final totalMinutes = activityData.fold(0, (sum, entry) => sum + entry.value);
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总时长
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '总时长',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(totalMinutes),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 图例列表
          Expanded(
            child: activityData.isEmpty 
              ? const Center(child: Text('暂无数据')) 
              : ListView.builder(
                  itemCount: activityData.length,
                  itemBuilder: (context, index) {
                    final entry = activityData[index];
                    final color = _chartColors[index % _chartColors.length];
                    final isSelected = _selectedTag == entry.key;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectTag(entry.key),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? color.withOpacity(0.2) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                            border: isSelected
                                ? Border.all(color: color)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(entry.value),
                                style: TextStyle(
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  // 格式化时长（分钟转为小时和分钟）
  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '$hours小时${mins > 0 ? ' $mins分钟' : ''}';
    } else {
      return '$mins分钟';
    }
  }

  // 构建活动记录列表
  Widget _buildActivityList() {
    if (_selectedTag == null) {
      return const SizedBox.shrink();
    }

    if (_selectedTagActivities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('没有找到与"$_selectedTag"相关的活动记录'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '"$_selectedTag"活动记录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('关闭'),
                onPressed: () {
                  setState(() {
                    _selectedTag = null;
                    _selectedTagActivities = [];
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300, // 固定高度，避免布局问题
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _selectedTagActivities.length,
            itemBuilder: (context, index) {
              final activity = _selectedTagActivities[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    activity.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('MM-dd HH:mm').format(activity.startTime)} - '
                        '${DateFormat('HH:mm').format(activity.endTime)}',
                      ),
                      if (activity.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: activity.tags
                              .map((tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                  trailing: Text(
                    activity.formattedDuration,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}