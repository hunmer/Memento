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
  DateTime _focusedDay = DateTime.now();
  var _forceRefresh = 0;
  final ScrollController _scrollController = ScrollController();

  Widget _dayCellBuilder(BuildContext context, DateTime date, _) {
    final calendarController = widget.calendarController;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.calendarController.selectDate(DateTime.now());
      if (mounted) setState(() {});
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
        appBar: _buildAppBar(context, l10n, calendarController, isExpanded),
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

  AppBar _buildAppBar(
    BuildContext context,
    dynamic l10n,
    CalendarController calendarController,
    bool isExpanded,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('日历日记', style: TextStyle(fontSize: 18)),
      actions: [
        IconButton(
          icon: Icon(isExpanded ? Icons.unfold_less : Icons.unfold_more),
          onPressed: () => setState(() => calendarController.toggleExpanded()),
          tooltip:
              isExpanded
                  ? l10n.get('collapseCalendar')
                  : l10n.get('expandCalendar'),
        ),
      ],
    );
  }

  Widget _buildCalendarListView(
    CalendarController calendarController,
    DateTime selectedDate,
  ) {
    DateTime? _lastLoadTime;
    double? _lastScrollPosition;
    bool _isScrollingDown = false;
    double _lastScrollTime = 0;
    double _scrollSpeed = 0;

    return Expanded(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              final now = DateTime.now().millisecondsSinceEpoch.toDouble();
              final canLoad =
                  _lastLoadTime == null ||
                  DateTime.now().difference(_lastLoadTime!) >
                      Duration(milliseconds: 500);

              // 精确判断滚动方向
              if (_lastScrollPosition != null && _lastScrollTime != 0) {
                final delta = metrics.pixels - _lastScrollPosition!;
                _isScrollingDown = delta > 2;
              }
              _lastScrollPosition = metrics.pixels;
              _lastScrollTime = now;
              // 仅保留向前加载逻辑
              if (metrics.pixels < 50 && // 接近顶部时触发
                  canLoad &&
                  !_isScrollingDown) {
                calendarController.loadMoreMonths(true);
                _lastLoadTime = now as DateTime?;
                setState(() => _forceRefresh++);
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            key: ValueKey(_forceRefresh), // 强制重建ListView
            itemCount: calendarController.displayMonths.length,
            itemBuilder: (context, index) {
              final month = calendarController.displayMonths[index];
              return TableCalendar(
                firstDay: DateTime(month.year, month.month, 1),
                lastDay: DateTime(month.year, month.month + 1, 0),
                focusedDay: month,
                headerVisible: true,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                onFormatChanged: (_) => setState(() {}),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  markersAutoAligned: true,
                ),
                selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  calendarController.selectDate(selectedDay);
                  setState(() => _focusedDay = focusedDay);
                },
                onHeaderTapped:
                    (_) => _showDatePicker(context, calendarController),
                onPageChanged:
                    calendarController.displayMonths.length > 1
                        ? (focusedDay) {
                          setState(() {
                            calendarController.currentMonth = focusedDay;
                            if (index == 0) {
                              calendarController.loadMoreMonths(true);
                              // 强制重建ListView以显示新加载的月份
                              _forceRefresh++;
                            }
                          });
                        }
                        : null,
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: _dayCellBuilder,
                  selectedBuilder: _dayCellBuilder,
                ),
              );
            },
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
        onTap:
            (entry) => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(value: calendarController),
                        ChangeNotifierProvider.value(value: tagController),
                      ],
                      child: EntryDetailScreen(
                        entry: entry,
                        date: selectedDate,
                      ),
                    ),
              ),
            ),
        onEdit:
            (entry) async => await Navigator.push(
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
            ),
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
      onPressed:
          () async => await Navigator.push(
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
          ),
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
    );
    if (selectedDate != null) {
      setState(() => _focusedDay = selectedDate);
      calendarController.selectDate(selectedDate);
    }
  }
}
