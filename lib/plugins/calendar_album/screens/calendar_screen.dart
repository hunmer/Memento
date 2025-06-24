import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../widgets/entry_list.dart';
import 'entry_editor_screen.dart';
import 'entry_detail_screen.dart';
import '../utils/date_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DateTime _focusedDay = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  Widget _dayCellBuilder(BuildContext context, DateTime date, _) {
    final calendarController = Provider.of<CalendarController>(context);
    final entries = calendarController.getEntriesForDate(date);
    final isSelected = isSameDay(date, calendarController.selectedDate);
    final isCurrentMonth = date.month == _focusedDay.month;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            isSelected ? Theme.of(context).primaryColor.withOpacity(0.3) : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                color: isCurrentMonth ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (entries.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    entries.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      // 只在首次初始化时跳转到当前日期
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Provider.of<CalendarController>(
            context,
            listen: false,
          ).selectDate(DateTime.now());
          setState(() => _isInitialized = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = CalendarAlbumLocalizations.of(context);
    final calendarController = Provider.of<CalendarController>(context);
    final tagController = Provider.of<TagController>(context);
    final selectedDate = calendarController.selectedDate;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: calendarController),
        ChangeNotifierProvider.value(value: tagController),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context, l10n),
        body: Column(
          children: [
            _buildCalendarListView(calendarController, selectedDate),
            _buildEntryList(
              context,
              calendarController,
              tagController,
              selectedDate,
              l10n,
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(
          context,
          calendarController,
          tagController,
          selectedDate,
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, dynamic l10n) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => PluginManager.toHomeScreen(context),
      ),
      title: const Text('日历日记', style: TextStyle(fontSize: 18)),
      actions: [
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              Provider.of<CalendarController>(
                context,
                listen: false,
              ).selectDate(DateTime.now());
            });
          },
          tooltip: '回到当前月份',
        ),
      ],
    );
  }

  Widget _buildCalendarListView(
    CalendarController calendarController,
    DateTime selectedDate,
  ) {
    return SizedBox(
      height: 360, // 固定高度
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: TableCalendar(
          firstDay: DateTime(_focusedDay.year, _focusedDay.month, 1),
          lastDay: DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
          focusedDay: _focusedDay,
          headerVisible: true,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            markersAutoAligned: true,
          ),
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (selectedDay, focusedDay) {
            Provider.of<CalendarController>(
              context,
              listen: false,
            ).selectDate(selectedDay);
            setState(() => _focusedDay = focusedDay);
          },
          onHeaderTapped: (_) => _showDatePicker(context, calendarController),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            leftChevronIcon: IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                  );
                });
              },
            ),
            rightChevronIcon: IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                  );
                });
              },
            ),
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: _dayCellBuilder,
            selectedBuilder: _dayCellBuilder,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryList(
    BuildContext context,
    CalendarController calendarController,
    TagController tagController,
    DateTime selectedDate,
    dynamic l10n,
  ) {
    return Expanded(
      child: EntryList(
        entries: calendarController.getEntriesForDate(selectedDate),
        onTap: (entry) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: calendarController),
                      ChangeNotifierProvider.value(value: tagController),
                    ],
                    child: EntryDetailScreen(entry: entry),
                  ),
            ),
          );
          if (mounted) setState(() {});
        },
        onEdit: (entry) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: calendarController),
                      ChangeNotifierProvider.value(value: tagController),
                    ],
                    child: EntryEditorScreen(entry: entry, isEditing: true),
                  ),
            ),
          );
          if (mounted) {
            calendarController.selectDate(selectedDate);
            setState(() {});
          }
        },
        onDelete:
            (entry) => showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(l10n.get('delete')),
                    content: Text('${l10n.get('delete')} "${entry.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.get('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          calendarController.deleteEntry(entry);
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: Text(l10n.get('delete')),
                      ),
                    ],
                  ),
            ),
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    CalendarController calendarController,
    TagController tagController,
    DateTime selectedDate,
  ) {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryEditorScreen(
                    initialDate: selectedDate,
                    isEditing: false,
                  ),
                ),
          ),
        );
        if (mounted) {
          calendarController.selectDate(selectedDate);
          setState(() {});
        }
      },
      child: const Icon(Icons.add),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    CalendarController calendarController,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: '选择年月',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (selectedDate != null) {
      setState(() {
        _focusedDay = DateTime(selectedDate.year, selectedDate.month);
      });
      Provider.of<CalendarController>(
        context,
        listen: false,
      ).selectDate(DateTime(selectedDate.year, selectedDate.month));
    }
  }
}
