import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/storage_manager.dart';
import 'diary_editor_screen.dart';
import '../models/diary_entry.dart';
import '../utils/diary_utils.dart';

class DiaryCalendarScreen extends StatefulWidget {
  final StorageManager storage;

  const DiaryCalendarScreen({super.key, required this.storage});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, DiaryEntry> _diaryEntries = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    final entries = await DiaryUtils.loadDiaryEntries();
    if (mounted) {
      setState(() {
        _diaryEntries = entries;
        // 确保选中日期也是标准化的
        _selectedDay = DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        );
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // 检查选择的日期是否大于今天
    if (selectedDay.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不能选择未来的日期'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 标准化选中的日期
    final normalizedSelectedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    setState(() {
      _selectedDay = normalizedSelectedDay;
      _focusedDay = focusedDay;
    });

    // 导航到日记编辑界面
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => DiaryEditorScreen(
                  date: normalizedSelectedDay,
                  storage: widget.storage,
                  initialTitle:
                      _diaryEntries[normalizedSelectedDay]?.title ?? '',
                  initialContent:
                      _diaryEntries[normalizedSelectedDay]?.content ?? '',
                ),
          ),
        )
        .then((_) => _loadDiaryEntries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: const Text('我的日记'),
        actions: [
         
        ],
      ),
      body: Column(
        children: [
          TableCalendar<DiaryEntry>(
            firstDay: DateTime.utc(2020, 1, 1),
            daysOfWeekHeight: 40, // 设置星期行的高度
            rowHeight: 85, // 设置日期行的高度
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              if (_diaryEntries.containsKey(normalizedDay)) {
                return [_diaryEntries[normalizedDay]!];
              }
              return [];
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              holidayTextStyle: const TextStyle(color: Colors.red),
              cellMargin: const EdgeInsets.all(4),
              // 使用新的方式控制单元格大小
              cellPadding: const EdgeInsets.all(8),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<DiaryEntry>(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                final entry = events.first;
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entry.mood != null)
                        Text(entry.mood!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.content.length}字',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_diaryEntries.containsKey(_selectedDay))
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy年MM月dd日').format(_selectedDay),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      if (_diaryEntries[_selectedDay]?.title.isNotEmpty ?? false)
                        Text(
                          ' - ${_diaryEntries[_selectedDay]!.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      const SizedBox(width: 8),
                      if (_diaryEntries[_selectedDay]?.mood != null)
                        Text(
                          _diaryEntries[_selectedDay]!.mood!,
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _diaryEntries[_selectedDay]?.content ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
