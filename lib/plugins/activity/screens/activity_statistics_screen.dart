import 'dart:math';

import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/activity_service.dart';
import '../models/activity_record.dart';
import 'tag_statistics_screen.dart';

/// 活动统计页面
class ActivityStatisticsScreen extends StatefulWidget {
  final ActivityService activityService;

  const ActivityStatisticsScreen({super.key, required this.activityService});

  @override
  State<ActivityStatisticsScreen> createState() =>
      _ActivityStatisticsScreenState();
}

class _ActivityStatisticsScreenState extends State<ActivityStatisticsScreen> {
  // 时间范围选择
  late String _selectedRange;
  late List<String> _timeRanges;

  // 日期范围
  DateTime? _startDate;
  DateTime? _endDate;

  // 活动数据
  List<ActivityRecord> _activities = [];
  bool _isLoading = false;

  // 选中的标签及其对应的活动
  String? _selectedTag;
  List<ActivityRecord> _selectedTagActivities = [];

  // Chart colors matching the reference design approximately
  final List<Color> _chartColors = const [
    Color(0xFF60A5FA), // blue-400
    Color(0xFF4ADE80), // green-400
    Color(0xFF818CF8), // indigo-400
    Color(0xFFFB923C), // orange-400
    Color(0xFFF87171), // red-400
    Color(0xFFFACC15), // yellow-400
    Color(0xFF2DD4BF), // teal-400
    Color(0xFFA78BFA), // purple-400
  ];

  @override
  void initState() {
    super.initState();
    _updateDateRange('Today');
  }

  Color _getColorForTag(String tag) {
    if (tag.isEmpty) return Colors.grey;
    final int hash = tag.hashCode;
    return _chartColors[hash.abs() % _chartColors.length];
  }

  // 更新日期范围并加载数据
  Future<void> _updateDateRange(String range) async {
    // 切换日期范围时，重置选中的标签和活动列表
    setState(() {
      _selectedTag = null;
      _selectedTagActivities = [];
      _selectedRange = range;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime start;
    DateTime end;

    switch (range) {
      case 'Today':
        start = today;
        end = todayEnd;
        break;
      case 'This Week':
        start = today.subtract(Duration(days: now.weekday - 1));
        end = todayEnd;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = todayEnd;
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = todayEnd;
        break;
      case 'Custom Range':
        if (_startDate == null || _endDate == null) {
          start = today;
          end = todayEnd;
        } else {
          start = _startDate!;
          end = _endDate!;
        }

        setState(() {
          _startDate = start;
          _endDate = end;
        });

        await _showDateRangePicker();
        return;

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

    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? now;
    final validEnd = initialEnd.isAfter(lastDate) ? lastDate : initialEnd;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: initialStart, end: validEnd),
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

      for (
        var date = _startDate!;
        date.isBefore(_endDate!.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dailyActivities = await widget.activityService
            .getActivitiesForDate(date);
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
          SnackBar(
            content: Text(
              '${ActivityLocalizations.of(context).loadingFailed}: $e',
            ),
          ),
        );
      }
    }
  }

  // 计算活动类型占比数据
  List<MapEntry<String, int>> _calculateActivityDistribution() {
    final Map<String, int> tagMinutes = {};

    for (var activity in _activities) {
      final duration = activity.durationInMinutes;

      if (activity.tags.isEmpty) {
        final unnamedKey = ActivityLocalizations.of(context).unnamedActivity;
        tagMinutes[unnamedKey] = (tagMinutes[unnamedKey] ?? 0) + duration;
      } else {
        final minutesPerTag = duration ~/ activity.tags.length;
        for (var tag in activity.tags) {
          tagMinutes[tag] = (tagMinutes[tag] ?? 0) + minutesPerTag;
        }
      }
    }

    final sortedEntries =
        tagMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries;
  }

  // 根据标签筛选活动

  // 选择标签并显示相关活动

  String _getRangeText(String range, BuildContext context) {
    switch (range) {
      case 'Today':
        return ActivityLocalizations.of(context).today;
      case 'This Week':
        return ActivityLocalizations.of(context).weekRange;
      case 'This Month':
        return ActivityLocalizations.of(context).monthRange;
      case 'This Year':
        return ActivityLocalizations.of(context).yearRange;
      case 'Custom Range':
        return ActivityLocalizations.of(context).customRange;
      default:
        return range;
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final localizations = ActivityLocalizations.of(context);

    if (hours > 0) {
      return '$hours${localizations.hour}${mins > 0 ? ' $mins${localizations.minute}' : ''}';
    } else {
      return '$mins${localizations.minute}';
    }
  }

  @override
  Widget build(BuildContext context) {
    _timeRanges = [
      'Today',
      'This Week',
      'This Month',
      'This Year',
      'Custom Range',
    ];

    return Scaffold(
      body: Column(
        children: [
          _buildDateRangeSelector(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${DateFormat('yyyy-MM-dd').format(_startDate!)} ${ActivityLocalizations.of(context).to} ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActivityProportionCard(),
                    const SizedBox(height: 16),
                    // Only show 24h distribution if range is Today or single day
                    if (_selectedRange == 'Today' ||
                        (_startDate != null &&
                            _endDate != null &&
                            _startDate!.year == _endDate!.year &&
                            _startDate!.month == _endDate!.month &&
                            _startDate!.day == _endDate!.day)) ...[
                      _build24hDistributionCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildActivityRankingCard(),
                    if (_selectedTag != null) ...[
                      const SizedBox(height: 16),
                      _buildActivityList(),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _timeRanges.map((range) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getRangeText(range, context)),
                    selected: _selectedRange == range,
                    onSelected: (selected) {
                      if (selected) _updateDateRange(range);
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActivityProportionCard() {
    final activityData = _calculateActivityDistribution();
    final totalMinutes = activityData.fold(
      0,
      (sum, entry) => sum + entry.value,
    );

    if (activityData.isEmpty) {
      return _buildCard(
        title: ActivityLocalizations.of(context).activityDistributionTitle,
        child: Center(child: Text(ActivityLocalizations.of(context).noData)),
      );
    }

    // Consolidate small segments for the pie chart if too many
    final List<MapEntry<String, int>> chartData;
    if (activityData.length > 5) {
      final topEntries = activityData.take(4).toList();
      final otherMinutes = activityData
          .skip(4)
          .fold(0, (sum, entry) => sum + entry.value);
      // Check if "Other" already exists (unlikely in this logic but safe to check)
      topEntries.add(
        MapEntry(
          ActivityLocalizations.of(context).unnamedActivity,
          otherMinutes,
        ),
      );
      chartData = topEntries;
    } else {
      chartData = activityData;
    }

    return _buildCard(
      title: ActivityLocalizations.of(context).activityDistributionTitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pie Chart
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 160,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: List.generate(chartData.length, (index) {
                        final entry = chartData[index];
                        final isSelected = _selectedTag == entry.key;
                        final color = _getColorForTag(entry.key);
                        return PieChartSectionData(
                          color: color,
                          value: entry.value.toDouble(),
                          title: '',
                          radius: isSelected ? 14 : 10,
                        );
                      }),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (totalMinutes ~/ 60).toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ActivityLocalizations.of(context).hour,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  chartData.take(4).map((entry) {
                    // Show top 4 in legend
                    final percentage = (entry.value / totalMinutes * 100)
                        .toStringAsFixed(1);
                    final color = _getColorForTag(entry.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build24hDistributionCard() {
    // Need to sort activities by time
    final sortedActivities = List<ActivityRecord>.from(_activities)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<Widget> segments = [];
    int currentMinute = 0;
    const totalMinutes = 1440;

    for (var activity in sortedActivities) {
      // Normalize to today's minutes (0-1440)
      // Note: This assumes _activities are filtered for a single day
      // If an activity spans across days, this logic needs to be robust.
      // For simplicity given the "Today" constraint, we calculate minutes from 00:00 of the activity's day.
      // If startDate is set, use it as base.
      final baseDate = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );

      int startM = activity.startTime.difference(baseDate).inMinutes;
      int endM = activity.endTime.difference(baseDate).inMinutes;

      // Clamp to 0-1440
      startM = startM.clamp(0, totalMinutes);
      endM = endM.clamp(0, totalMinutes);

      if (startM > currentMinute) {
        // Gap
        final gap = startM - currentMinute;
        if (gap > 0) {
          segments.add(
            Expanded(
              flex: gap,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ); // Use background color for gaps
        }
      }
      
      final duration = endM - startM;
      if (duration > 0) {
        String tag =
            activity.tags.isNotEmpty
                ? activity.tags.first
                : ActivityLocalizations.of(context).unnamedActivity;
        segments.add(
          Expanded(
            flex: duration,
            child: Container(
              color: _getColorForTag(tag),
              alignment: Alignment.center,
              child:
                  duration > 30
                      ? Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                      : null,
            ),
          ),
        );
      }
      currentMinute = max(currentMinute, endM);
    }

    if (currentMinute < totalMinutes) {
      segments.add(
        Expanded(
          flex: totalMinutes - currentMinute,
          child: Container(color: Theme.of(context).scaffoldBackgroundColor),
        ),
      );
    }

    return _buildCard(
      title:
          '24${ActivityLocalizations.of(context).hour} ${ActivityLocalizations.of(context).timeDistributionTitle}', // Hack: "24小时分布" if "timeDistributionTitle" is "时间分布"
      // Better to use existing keys. "Time Distribution" is "时间分布".
      // Just use "24h Distribution" or combine keys if needed.
      // I'll use "24H Distribution" hardcoded for now or generic title.
      // Actually, let's just use "24H" + Title
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children:
                    segments.isEmpty
                        ? [Expanded(child: Container(color: Colors.grey[200]))]
                        : segments,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('00:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('06:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('12:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('18:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('24:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRankingCard() {
    final activityData =
        _calculateActivityDistribution(); // This is already sorted by duration desc

    if (activityData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxDuration = activityData.first.value;

    return _buildCard(
      title:
          ActivityLocalizations.of(
            context,
          ).statistics, // Or "Activity Duration Ranking"
      child: Column(
        children:
            activityData.map((entry) {
              final tag = entry.key;
              final duration = entry.value;
              final color = _getColorForTag(tag);
              final progress = duration / maxDuration;

              return InkWell(
                onTap: () {
                  NavigationHelper.push(context, TagStatisticsScreen(
                            tagName: tag,
                            activityService: widget.activityService,),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.local_activity,
                          size: 16,
                          color: color,
                        ), // Generic icon
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                                color: color,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // 构建活动记录列表
  Widget _buildActivityList() {
    if (_selectedTag == null || _selectedTagActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildCard(
      title:
          '${ActivityLocalizations.of(context).activityRecords} - $_selectedTag',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _selectedTagActivities.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final activity = _selectedTagActivities[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              activity.title.isEmpty
                  ? ActivityLocalizations.of(context).unnamedActivity
                  : activity.title,
            ),
            subtitle: Text(
              '${DateFormat('HH:mm').format(activity.startTime)} - ${DateFormat('HH:mm').format(activity.endTime)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            trailing: Text(
              _formatDuration(activity.durationInMinutes),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
