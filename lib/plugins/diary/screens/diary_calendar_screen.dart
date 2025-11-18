import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/diary/l10n/diary_localizations.dart';
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
  Map<DateTime, DiaryEntry> _diaryEntries = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    final entries = await DiaryUtils.loadDiaryEntries();
    if (mounted) {
      setState(() {
        _diaryEntries = entries;
      });
    }
  }

  void _onDayClicked(DateTime selectedDay, DateTime focusedDay) {
    // 检查选择的日期是否大于今天
    if (selectedDay.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DiaryLocalizations.of(context).cannotSelectFutureDate),
          duration: const Duration(seconds: 2),
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
        title: Text(DiaryLocalizations.of(context).myDiary),
        actions: [],
      ),
      body: TableCalendar<DiaryEntry>(
              firstDay: DateTime.utc(2020, 1, 1),
        daysOfWeekHeight: 45,
        rowHeight: 95,
              lastDay: DateTime.now(),
        focusedDay: _focusedDay,
              onDaySelected: (selectedDay, focusedDay) {
          _onDayClicked(selectedDay, focusedDay);
              },
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
          weekendTextStyle: TextStyle(color: Colors.red.shade400, fontSize: 16),
          holidayTextStyle: TextStyle(color: Colors.red.shade400, fontSize: 16,
                ),
          cellMargin: const EdgeInsets.all(2),
          cellPadding: const EdgeInsets.all(4),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
            fontSize: 16,
                ),
          defaultTextStyle: const TextStyle(fontSize: 16),
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
              margin: const EdgeInsets.only(top: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.mood != null)
                          Text(
                            entry.mood!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.content.length}字',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                dowBuilder: (context, day) {
            bool isWeekend =
                day.weekday == DateTime.saturday ||
                day.weekday == DateTime.sunday;
                  return Center(
                    child: Text(
                      DateFormat.E().format(day),
                      style: TextStyle(
                  color: isWeekend ? Colors.red.shade400 : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
            bool isWeekend =
                day.weekday == DateTime.saturday ||
                day.weekday == DateTime.sunday;

            return Container(
              margin: const EdgeInsets.all(2),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isWeekend ? Colors.red.shade400 : null,
                    fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
        ),
      ),
    );
  }
}
