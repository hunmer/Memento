import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:Memento/widgets/memento_sf_calendar/memento_sf_calendar.dart';

/// MementoSfCalendar 示例展示页面
class MementoSfCalendarExample extends StatefulWidget {
  const MementoSfCalendarExample({super.key});

  @override
  State<MementoSfCalendarExample> createState() =>
      _MementoSfCalendarExampleState();
}

class _MementoSfCalendarExampleState extends State<MementoSfCalendarExample> {
  final CalendarController _controller = CalendarController();

  // 可交互配置
  CalendarView _currentView = CalendarView.month;
  bool _showAgenda = true;
  bool _showWeekNumber = false;
  bool _showNavigationArrow = true;
  bool _showDatePickerButton = true;
  bool _showTodayButton = true;
  bool _showCurrentTimeIndicator = true;
  bool _allowDragAndDrop = false;
  bool _allowAppointmentResize = false;
  bool _allowViewNavigation = true;
  double _startHour = 6;
  double _endHour = 23;
  int _firstDayOfWeek = 1;

  @override
  void initState() {
    super.initState();
    _controller.view = _currentView;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 生成示例事件数据
  CalendarDataSource _getDataSource() {
    final now = DateTime.now();
    final appointments = <Appointment>[
      Appointment(
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 30),
        subject: '项目会议',
        color: Colors.blue,
        notes: '讨论Q1计划',
      ),
      Appointment(
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 0),
        subject: '代码评审',
        color: Colors.green,
      ),
      Appointment(
        startTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 11, 0),
        subject: '客户演示',
        color: Colors.orange,
      ),
      Appointment(
        startTime: DateTime(now.year, now.month, now.day + 2, 8, 0),
        endTime: DateTime(now.year, now.month, now.day + 2, 17, 0),
        subject: '全天培训',
        color: Colors.purple,
        isAllDay: true,
      ),
      Appointment(
        startTime: DateTime(now.year, now.month, now.day - 1, 16, 0),
        endTime: DateTime(now.year, now.month, now.day - 1, 17, 30),
        subject: '团队下午茶',
        color: Colors.teal,
      ),
      Appointment(
        startTime: DateTime(now.year, now.month, now.day + 3, 13, 0),
        endTime: DateTime(now.year, now.month, now.day + 3, 14, 0),
        subject: '一对一沟通',
        color: Colors.red,
      ),
    ];
    return _SampleDataSource(appointments);
  }

  /// 生成特殊时间区域（午休）
  List<TimeRegion> _getSpecialRegions() {
    final now = DateTime.now();
    return [
      TimeRegion(
        startTime: DateTime(now.year, now.month, now.day, 12, 0),
        endTime: DateTime(now.year, now.month, now.day, 13, 0),
        text: '午休',
        enablePointerInteraction: false,
        color: Colors.grey.withValues(alpha: 0.2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MementoSfCalendar 示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsSheet,
            tooltip: '自定义设置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 视图切换按钮
          _buildViewSelector(theme),
          const Divider(height: 1),
          // 日历
          Expanded(
            child: MementoSfCalendar(
              view: _currentView,
              controller: _controller,
              allowedViews: const [
                CalendarView.day,
                CalendarView.week,
                CalendarView.workWeek,
                CalendarView.month,
                CalendarView.timelineDay,
                CalendarView.timelineWeek,
                CalendarView.timelineWorkWeek,
                CalendarView.schedule,
              ],
              allowViewNavigation: _allowViewNavigation,
              initialDisplayDate: DateTime.now(),
              firstDayOfWeek: _firstDayOfWeek,
              dataSource: _getDataSource(),
              // 月视图
              showAgenda: _showAgenda,
              agendaViewHeight: 180,
              appointmentDisplayMode:
                  MonthAppointmentDisplayMode.appointment,
              // 时间槽
              startHour: _startHour,
              endHour: _endHour,
              timeInterval: const Duration(minutes: 30),
              // 外观
              todayHighlightColor: theme.primaryColor,
              showWeekNumber: _showWeekNumber,
              showNavigationArrow: _showNavigationArrow,
              showDatePickerButton: _showDatePickerButton,
              showTodayButton: _showTodayButton,
              showCurrentTimeIndicator: _showCurrentTimeIndicator,
              // 高级
              allowDragAndDrop: _allowDragAndDrop,
              allowAppointmentResize: _allowAppointmentResize,
              specialRegions: _getSpecialRegions(),
              // 回调
              onViewChanged: (details) {
                if (details.visibleDates.isNotEmpty) {
                  // 视图变化
                }
              },
              onTap: (details) {
                if (details.appointments != null &&
                    details.appointments!.isNotEmpty) {
                  final appointment =
                      details.appointments!.first as Appointment;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('点击: ${appointment.subject}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              onDragEnd: _allowDragAndDrop
                  ? (details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '拖放事件到 ${details.droppingTime}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 视图选择器
  Widget _buildViewSelector(ThemeData theme) {
    final views = <MapEntry<CalendarView, String>>[
      const MapEntry(CalendarView.day, '日'),
      const MapEntry(CalendarView.week, '周'),
      const MapEntry(CalendarView.workWeek, '工作周'),
      const MapEntry(CalendarView.month, '月'),
      const MapEntry(CalendarView.timelineDay, '时间线'),
      const MapEntry(CalendarView.schedule, '日程'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: views.map((entry) {
          final isSelected = _currentView == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _currentView = entry.key;
                  _controller.view = entry.key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 设置面板
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '日历自定义设置',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // 导航与显示
                    _buildSectionTitle('导航与显示'),
                    _buildSwitchTile(
                      '显示导航箭头',
                      _showNavigationArrow,
                      (v) {
                        setSheetState(() => _showNavigationArrow = v);
                        setState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      '显示日期选择按钮',
                      _showDatePickerButton,
                      (v) {
                        setSheetState(() => _showDatePickerButton = v);
                        setState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      '显示今日按钮',
                      _showTodayButton,
                      (v) {
                        setSheetState(() => _showTodayButton = v);
                        setState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      '允许视图导航',
                      _allowViewNavigation,
                      (v) {
                        setSheetState(() => _allowViewNavigation = v);
                        setState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      '显示当前时间指示器',
                      _showCurrentTimeIndicator,
                      (v) {
                        setSheetState(() => _showCurrentTimeIndicator = v);
                        setState(() {});
                      },
                    ),

                    // 月视图选项
                    _buildSectionTitle('月视图'),
                    _buildSwitchTile(
                      '显示议程',
                      _showAgenda,
                      (v) {
                        setSheetState(() => _showAgenda = v);
                        setState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      '显示周数',
                      _showWeekNumber,
                      (v) {
                        setSheetState(() => _showWeekNumber = v);
                        setState(() {});
                      },
                    ),

                    // 时间槽选项
                    _buildSectionTitle('时间槽视图'),
                    ListTile(
                      title: const Text('开始时间'),
                      subtitle: Slider(
                        value: _startHour,
                        min: 0,
                        max: 12,
                        divisions: 12,
                        label: '${_startHour.toInt()}:00',
                        onChanged: (v) {
                          setSheetState(() => _startHour = v);
                          setState(() {});
                        },
                      ),
                      trailing: Text('${_startHour.toInt()}:00'),
                    ),
                    ListTile(
                      title: const Text('结束时间'),
                      subtitle: Slider(
                        value: _endHour,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: '${_endHour.toInt()}:00',
                        onChanged: (v) {
                          setSheetState(() => _endHour = v);
                          setState(() {});
                        },
                      ),
                      trailing: Text('${_endHour.toInt()}:00'),
                    ),

                    // 交互选项
                    _buildSectionTitle('交互'),
                    _buildSwitchTile(
                      '允许拖放事件',
                      _allowDragAndDrop,
                      (v) {
                        setSheetState(() => _allowDragAndDrop = v);
                        setState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      '允许调整事件大小',
                      _allowAppointmentResize,
                      (v) {
                        setSheetState(() => _allowAppointmentResize = v);
                        setState(() {});
                      },
                    ),

                    // 每周起始日
                    _buildSectionTitle('其他'),
                    ListTile(
                      title: const Text('每周起始日'),
                      trailing: DropdownButton<int>(
                        value: _firstDayOfWeek,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('周一')),
                          DropdownMenuItem(value: 7, child: Text('周日')),
                          DropdownMenuItem(value: 6, child: Text('周六')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => _firstDayOfWeek = v);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }
}

/// 示例数据源
class _SampleDataSource extends CalendarDataSource {
  _SampleDataSource(List<Appointment> source) {
    appointments = source;
  }
}
