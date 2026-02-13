import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';
import 'package:Memento/core/plugin_manager.dart';

/// 习惯月份列表视图
///
/// 显示某个习惯在选中月份的完成记录，类似于账单的月视图
class HabitMonthlyListScreen extends StatefulWidget {
  final String habitId;
  final String habitTitle;

  const HabitMonthlyListScreen({
    super.key,
    required this.habitId,
    required this.habitTitle,
  });

  @override
  State<HabitMonthlyListScreen> createState() =>
      _HabitMonthlyListScreenState();
}

class _HabitMonthlyListScreenState extends State<HabitMonthlyListScreen> {
  late CalendarController _calendarController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data State
  List<_CompletionRecordModel> _allMonthRecords = [];
  Map<DateTime, _DailyStats> _dailyStats = {};

  // Colors
  static const Color _primaryColor = Color(0xFF607AFB);

  late HabitsPlugin _habitsPlugin;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _calendarController = CalendarController();
    _calendarController.displayDate = DateTime.now();
    _calendarController.selectedDate = DateTime.now();

    _habitsPlugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin;

    // 设置路由上下文
    _updateRouteContext(_focusedDay);

    _loadMonthRecords();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthRecords() async {
    final recordController = _habitsPlugin.getRecordController();
    final records = await recordController.getHabitCompletionRecords(
      widget.habitId,
    );

    // Filter by month
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
      23,
      59,
      59,
    );

    final filteredRecords = records.where(
      (record) =>
          record.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
          record.date.isBefore(monthEnd.add(const Duration(seconds: 1))),
    );

    // Calculate daily stats
    final stats = <DateTime, _DailyStats>{};
    for (var record in filteredRecords) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      if (!stats.containsKey(date)) {
        stats[date] = _DailyStats();
      }
      stats[date]!.count++;
      stats[date]!.totalMinutes += (record.duration.inMinutes as int);
    }

    if (mounted) {
      setState(() {
        _allMonthRecords = filteredRecords
            .map(
              (record) => _CompletionRecordModel(
                id: record.id,
                date: record.date,
                duration: record.duration,
                notes: record.notes,
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _dailyStats = stats;
      });
    }
  }

  Map<String, double> _getMonthStats(DateTime month) {
    // 返回默认值，实际数据在 _loadMonthRecords 中异步加载
    // 这里返回缓存值或默认值
    final stats = _dailyStats.entries.fold(
      {
        'count': 0.0,
        'totalMinutes': 0.0,
      },
      (acc, entry) {
        acc['count'] = (acc['count']! + entry.value.count);
        acc['totalMinutes'] =
            (acc['totalMinutes']! + entry.value.totalMinutes);
        return acc;
      },
    );
    return stats;
  }

  void _updateRouteContext(DateTime date, {DateTime? selectedDay}) {
    String dateStr;
    String title;

    if (selectedDay != null) {
      dateStr =
          '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
      title = '${widget.habitTitle} - $dateStr';
    } else {
      dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      title = '${widget.habitTitle} - $dateStr';
    }

    RouteHistoryManager.updateCurrentContext(
      pageId: '/habit_monthly_list',
      title: title,
      params: {'date': dateStr},
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected) {
    final date = DateTime(day.year, day.month, day.day);
    final stats = _dailyStats[date];
    final isToday = _isSameDay(DateTime.now(), day);
    final hasRecord = (stats?.count ?? 0) > 0;

    return ConstrainedBox(
      constraints: BoxConstraints.tight(
        const Size(48, 48),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.2) : null,
          border: isToday ? Border.all(color: _primaryColor, width: 2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? _primaryColor : null,
              ),
            ),
            if (hasRecord)
              Positioned(
                top: -6,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${stats!.count}',
                    style: TextStyle(
                      fontSize: 7,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_CompletionRecordModel> get _selectedDayRecords {
    if (_selectedDay == null) return [];

    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    return _allMonthRecords.where((record) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return _isSameDay(recordDate, selectedDate);
    }).toList();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatCompactDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h}h${m > 0 ? '${m}m' : ''}';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text(widget.habitTitle),
      largeTitle: widget.habitTitle,
      enableLargeTitle: true,
      body: _buildMainBody(),
    );
  }

  Widget _buildMainBody() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month Selector
          MonthSelector(
            selectedMonth: _focusedDay,
            onMonthSelected: (month) async {
              setState(() {
                _focusedDay = month;
                _loadMonthRecords();
              });
              _updateRouteContext(month);
            },
            getMonthStats: _getMonthStats,
            primaryColor: _primaryColor,
            customStatsBuilder: (stats) {
              final count = stats['count'] ?? 0;
              final totalMinutes = stats['totalMinutes'] ?? 0;
              return Column(
                children: [
                  Text(
                    '$count次',
                    style: const TextStyle(
                      fontSize: 10,
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatCompactDuration(totalMinutes.toInt()),
                    style: const TextStyle(
                      fontSize: 10,
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
            maxDate: DateTime.now(),
          ),

          // Calendar
          SfCalendar(
            controller: _calendarController,
            view: CalendarView.month,
            initialDisplayDate: _focusedDay,
            minDate: DateTime(2020),
            maxDate: DateTime(2030),
            headerHeight: 0,
            viewHeaderHeight: 40,
            showNavigationArrow: false,
            monthViewSettings: const MonthViewSettings(
              showTrailingAndLeadingDates: false,
              dayFormat: 'EEE',
            ),
            cellBorderColor: Colors.transparent,
            selectionDecoration: const BoxDecoration(),
            todayHighlightColor: Colors.transparent,
            monthCellBuilder:
                (BuildContext context, MonthCellDetails details) {
              final day = details.date;
              final isSelected =
                  _selectedDay != null && _isSameDay(day, _selectedDay!);
              return _buildCalendarCell(day, isSelected);
            },
            onTap: (CalendarTapDetails details) {
              if (details.date != null) {
                setState(() {
                  _selectedDay = details.date;
                  _focusedDay = details.date!;
                  _calendarController.selectedDate = details.date;
                });
                _updateRouteContext(_focusedDay, selectedDay: _selectedDay);
              }
            },
            onViewChanged: (ViewChangedDetails details) {
              if (details.visibleDates.isNotEmpty) {
                final newFocusedDay =
                    details.visibleDates[details.visibleDates.length ~/ 2];
                _focusedDay = newFocusedDay;
                _loadMonthRecords();
                _updateRouteContext(newFocusedDay);
              }
            },
          ),

          // Daily Records List
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy年MM月dd日').format(_selectedDay!),
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_selectedDayRecords.length}次打卡)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDayRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '这天没有打卡记录',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedDayRecords.length,
                itemBuilder: (context, index) {
                  final record = _selectedDayRecords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _primaryColor.withOpacity(0.2),
                        child: Icon(Icons.check, color: _primaryColor),
                      ),
                      title: Text(
                        _formatDuration(record.duration),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('HH:mm').format(record.date)),
                          if (record.notes != null && record.notes!.isNotEmpty)
                            Text(
                              record.notes!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '请选择一天查看记录',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletionRecordModel {
  final String id;
  final DateTime date;
  final Duration duration;
  final String? notes;

  _CompletionRecordModel({
    required this.id,
    required this.date,
    required this.duration,
    this.notes,
  });
}

class _DailyStats {
  int count = 0;
  int totalMinutes = 0;
}
