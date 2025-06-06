import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../widgets/entry_list.dart';
import 'entry_editor_screen.dart';
import 'entry_detail_screen.dart' hide BoxDecoration, Center;
import '../utils/date_utils.dart';

class CalendarScreen extends StatefulWidget {
  final CalendarController calendarController;
  final TagController tagController;

  const CalendarScreen({
    super.key,
    required this.calendarController,
    required this.tagController,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 确保在初始化时就选择当天日期并加载对应的日记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.calendarController.selectDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final calendarController = widget.calendarController;
    final tagController = widget.tagController;
    final selectedDate = calendarController.selectedDate;
    final isExpanded = calendarController.isExpanded;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: calendarController),
        ChangeNotifierProvider.value(value: tagController),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: GestureDetector(
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: _focusedDay,
                firstDate: DateTime(2010),
                lastDate: DateTime(2030),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                initialDatePickerMode: DatePickerMode.year,
              ).then((selectedDate) {
                if (selectedDate != null) {
                  setState(() {
                    _focusedDay = selectedDate;
                  });
                  calendarController.selectDate(selectedDate);
                }
              });
            },
            child: Text('日历日记', style: const TextStyle(fontSize: 18)),
          ),
          actions: [
            IconButton(
              icon: Icon(isExpanded ? Icons.unfold_less : Icons.unfold_more),
              onPressed: () {
                calendarController.toggleExpanded();
              },
              tooltip:
                  isExpanded
                      ? l10n.get('collapseCalendar')
                      : l10n.get('expandCalendar'),
            ),
          ],
        ),
        body: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat:
                  isExpanded ? CalendarFormat.month : _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.week: 'Week',
              },
              onFormatChanged: (format) {
                if (!isExpanded) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              headerVisible: !isExpanded,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: isExpanded,
                markersAutoAligned: true,
              ),
              selectedDayPredicate: (day) {
                return isSameDay(selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                calendarController.selectDate(selectedDay);
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  final entries = calendarController.getEntriesForDate(date);
                  final hasImages = entries.any(
                    (entry) =>
                        entry.imageUrls.isNotEmpty ||
                        entry.extractImagesFromMarkdown().isNotEmpty,
                  );

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color:
                                  date.month == _focusedDay.month
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        if (entries.isNotEmpty)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                entries.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                selectedBuilder: (context, date, _) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Builder(
                builder:
                    (context) => EntryList(
                      entries: calendarController.getEntriesForDate(
                        selectedDate,
                      ),
                      onTap: (entry) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider<
                                      CalendarController
                                    >.value(value: calendarController),
                                    ChangeNotifierProvider<TagController>.value(
                                      value: tagController,
                                    ),
                                  ],
                                  child: EntryDetailScreen(
                                    entry: entry,
                                    date: calendarController.selectedDate,
                                  ),
                                ),
                          ),
                        );
                      },
                      onEdit: (entry) async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider.value(
                                      value: calendarController,
                                    ),
                                    ChangeNotifierProvider.value(
                                      value: tagController,
                                    ),
                                  ],
                                  child: EntryEditorScreen(
                                    entry: entry,
                                    isEditing: true,
                                  ),
                                ),
                          ),
                        );
                      },
                      onDelete: (entry) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(l10n.get('delete')),
                                content: Text(
                                  '${l10n.get('delete')} "${entry.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text(l10n.get('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      calendarController.deleteEntry(entry);
                                      Navigator.of(context).pop();
                                      setState(() {}); // 强制刷新界面
                                    },
                                    child: Text(l10n.get('delete')),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder:
              (context) => FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChangeNotifierProvider.value(
                            value: calendarController,
                            child: MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(
                                  value: calendarController,
                                ),
                                ChangeNotifierProvider.value(
                                  value: tagController,
                                ),
                              ],
                              child: EntryEditorScreen(
                                initialDate: selectedDate,
                                isEditing: false,
                              ),
                            ),
                          ),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
        ),
      ),
    );
  }
}
