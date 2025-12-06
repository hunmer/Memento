import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/activity_service.dart';
import '../models/activity_record.dart';
import '../../../core/services/toast_service.dart';

class TagStatisticsScreen extends StatefulWidget {
  final String tagName;
  final ActivityService activityService;

  const TagStatisticsScreen({
    super.key,
    required this.tagName,
    required this.activityService,
  });

  @override
  State<TagStatisticsScreen> createState() => _TagStatisticsScreenState();
}

class _TagStatisticsScreenState extends State<TagStatisticsScreen> {
  // Time Range Selection
  late String _selectedRange;
  late List<String> _timeRanges;
  DateTime? _startDate;
  DateTime? _endDate;

  // Data
  List<ActivityRecord> _activities = [];
  bool _isLoading = false;

  // Chart Colors
  final Color _primaryColor = const Color(0xFF4ADE80); // green-400 from HTML

  @override
  void initState() {
    super.initState();
    _updateDateRange(
      'This Month',
    ); // Default to This Month as it's close to 30 days
  }

  Future<void> _updateDateRange(String range) async {
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
        return; // Picker handles the load
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

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
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

  Future<void> _loadActivities() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final activities = <ActivityRecord>[];
      // Iterate days to get all activities
      for (
        var date = _startDate!;
        date.isBefore(_endDate!.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dailyActivities = await widget.activityService
            .getActivitiesForDate(date);
        // Filter by tag immediately
        final taggedActivities =
            dailyActivities.where((a) {
              if (widget.tagName ==
                  ActivityLocalizations.of(context).unnamedActivity) {
                return a.tags.isEmpty;
              }
              return a.tags.contains(widget.tagName);
            }).toList();
        activities.addAll(taggedActivities);
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
        toastService.showToast('Error loading data: $e');
      }
    }
  }

  // Helpers for Data Processing

  Map<DateTime, int> _getDailyDurations() {
    final Map<DateTime, int> data = {};
    // Initialize all days in range with 0
    if (_startDate != null && _endDate != null) {
      for (
        var date = _startDate!;
        date.isBefore(_endDate!.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        data[normalizedDate] = 0;
      }
    }

    for (var activity in _activities) {
      final date = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );
      // Handle activities spanning days? For now assuming simplified daily view or start time based
      if (data.containsKey(date)) {
        // Split duration if multiple tags?
        // Logic in statistics screen was: duration / tags.length
        int duration = activity.durationInMinutes;
        if (activity.tags.length > 1) {
          duration = duration ~/ activity.tags.length;
        }
        data[date] = (data[date] ?? 0) + duration;
      }
    }
    return data;
  }

  Map<int, double> _getWeeklyAverage() {
    final Map<int, List<int>> weekdayDurations = {};
    for (int i = 1; i <= 7; i++) {
      weekdayDurations[i] = [];
    }

    final dailyData = _getDailyDurations();
    dailyData.forEach((date, minutes) {
      weekdayDurations[date.weekday]?.add(minutes);
    });

    final Map<int, double> averages = {};
    weekdayDurations.forEach((weekday, values) {
      if (values.isEmpty) {
        averages[weekday] = 0.0;
      } else {
        averages[weekday] =
            values.reduce((a, b) => a + b) / values.length / 60.0; // Hours
      }
    });
    return averages;
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
      appBar: AppBar(title: Text(widget.tagName)),
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
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTrendChartCard(),
                    const SizedBox(height: 16),
                    _buildHeatmapCard(),
                    const SizedBox(height: 16),
                    _buildWeeklyDistributionCard(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    // Reusing logic from ActivityStatisticsScreen
    String getRangeText(String range) {
      // Simple mapping, ideally reuse localization logic or pass it in
      final localizations = ActivityLocalizations.of(context);
      switch (range) {
        case 'Today':
          return localizations.today;
        case 'This Week':
          return localizations.weekRange;
        case 'This Month':
          return localizations.monthRange;
        case 'This Year':
          return localizations.yearRange;
        case 'Custom Range':
          return localizations.customRange;
        default:
          return range;
      }
    }

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
                    label: Text(getRangeText(range)),
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

  Widget _buildTrendChartCard() {
    final dailyData = _getDailyDurations();
    // Sort by date
    final sortedKeys = dailyData.keys.toList()..sort();

    // Prepare spots
    final spots = <FlSpot>[];
    double maxHours = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final date = sortedKeys[i];
      final hours = dailyData[date]! / 60.0;
      if (hours > maxHours) maxHours = hours;
      spots.add(FlSpot(i.toDouble(), hours));
    }

    // If no data
    if (spots.isEmpty) {
      return _buildCard(
        title: 'Trend', // Localize?
        child: const SizedBox(
          height: 200,
          child: Center(child: Text('No Data')),
        ),
      );
    }

    return _buildCard(
      title:
          '${ActivityLocalizations.of(context).timeDistributionTitle} ($_selectedRange)', // Using available key roughly
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval:
                      (sortedKeys.length / 4)
                          .ceilToDouble(), // Show roughly 4 labels
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedKeys.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MM/dd').format(sortedKeys[index]),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}h',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (sortedKeys.length - 1).toDouble(),
            minY: 0,
            maxY: (maxHours * 1.2).ceilToDouble(), // Add some buffer
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: _primaryColor.withValues(alpha: 0.1),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _primaryColor.withValues(alpha: 0.2),
                      _primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapCard() {
    final dailyData = _getDailyDurations();
    final sortedKeys = dailyData.keys.toList()..sort();

    int maxMinutes = 1;
    dailyData.forEach((key, value) {
      if (value > maxMinutes) maxMinutes = value;
    });

    return _buildCard(
      title: ActivityLocalizations.of(context).activityRecords,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (sortedKeys.isEmpty) {
                return const SizedBox(height: 180);
              }

              const int crossAxisCount = 7;
              double crossAxisSpacing = 4.0;
              double mainAxisSpacing = 4.0;
              const double gridHeight = 180.0;

              final offset = sortedKeys.first.weekday == 7 ? 0 : sortedKeys.first.weekday;
              final int totalItems = sortedKeys.length + offset;
              final int numRows = (totalItems / crossAxisCount).ceil();

              // If too many rows, reduce spacing to prevent negative height
              if (numRows > 40) { // e.g. > ~9 months
                mainAxisSpacing = 1.0;
                crossAxisSpacing = 1.0;
              } else if (numRows > 20) { // e.g. > ~4.5 months
                mainAxisSpacing = 2.0;
                crossAxisSpacing = 2.0;
              }

              final double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
              final double itemHeight = (gridHeight - (numRows - 1) * mainAxisSpacing) / numRows;
              final double childAspectRatio = itemWidth > 0 && itemHeight > 0 ? itemWidth / itemHeight : 1.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  if (index < offset) {
                    return Container();
                  }

                  final dayIndex = index - offset;
                  if (dayIndex >= sortedKeys.length) return Container();

                  final date = sortedKeys[dayIndex];
                  final minutes = dailyData[date] ?? 0;
                  final intensity = (minutes / maxMinutes).clamp(0.0, 1.0);

                  Color color;
                  if (minutes == 0) {
                    color = Theme.of(context).dividerColor.withValues(alpha: 0.1);
                  } else if (intensity < 0.25) {
                    color = _primaryColor.withValues(alpha: 0.3);
                  } else if (intensity < 0.5) {
                    color = _primaryColor.withValues(alpha: 0.5);
                  } else if (intensity < 0.75) {
                    color = _primaryColor.withValues(alpha: 0.7);
                  } else {
                    color = _primaryColor;
                  }

                  return Tooltip(
                    message: '${DateFormat('yyyy-MM-dd').format(date)}: ${_formatDuration(minutes)}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(width: 4),
              Container(width: 10, height: 10, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, color: _primaryColor.withValues(alpha: 0.3)),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, color: _primaryColor.withValues(alpha: 0.5)),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, color: _primaryColor.withValues(alpha: 0.7)),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, color: _primaryColor),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDistributionCard() {
    final weeklyAverage = _getWeeklyAverage(); // map 1..7 -> avg hours
    final maxAvg = weeklyAverage.values.fold(0.0, (p, c) => c > p ? c : p);

    // Weekdays M-S. 1-7.
    // HTML shows labels Mon, Tue...

    return _buildCard(
      title:
          ActivityLocalizations.of(
            context,
          ).weekRange, // "Weekly Average" - reuse weekRange key or similar
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ), // Hide Y axis labels for cleaner look like HTML
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    final index = value.toInt() - 1;
                    if (index >= 0 && index < 7) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (index) {
              final weekday = index + 1;
              final val = weeklyAverage[weekday] ?? 0.0;
              return BarChartGroupData(
                x: weekday,
                barRods: [
                  BarChartRodData(
                    toY: val,
                    color: _primaryColor,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxAvg * 1.1, // Background bar full height
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                showingTooltipIndicators: [0],
              );
            }),
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.lightBlue,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toStringAsFixed(1)}h',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
